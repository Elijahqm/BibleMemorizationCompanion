using System.Globalization;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

// Content authoring tool for the Bible Memorization Companion.
//
//   dotnet run --project tools/ContentTool -- parse   <package|all>
//   dotnet run --project tools/ContentTool -- package <package|all>
//   dotnet run --project tools/ContentTool -- build   <package|all>   (parse + package)
//
// "parse"   reads the plain-text source and writes the reviewable content folder
//           (index.json, chapters/NNN.json, sections.json) under backend/content/{id}/content.
// "package" builds the distributable artifact (package.zip, manifest.json, package.sha256)
//           under wwwroot/packages/{id}/{version}.
//
// Text fidelity: verse text is taken verbatim from the source; the only change is
// collapsing runs of whitespace to a single space (flattening poetry) and removing
// footnote markers ("*") and standalone cross-reference lines. No words are modified.
//
// Section titles: where a section begins, the title travels *inside* the verse text as a
// marker "[[section:{id}|{Title}]]" so the client can format it differently (at the start
// of the verse, or mid-verse for a title that splits a verse). sections.json is the single
// source of truth for membership; a verse may belong to two sections at once (when a new
// section starts mid-verse, the whole verse is included in both).
//
// Source conventions for section titles:
//   * a title on its own line (after a blank line) starts a section at the *next* verse;
//   * a title written inline as "{{Title}}" inside a verse's text starts a section
//     *mid-verse* at that position, and that whole verse belongs to both sections.

var command = args.Length > 0 ? args[0] : "build";
var target = args.Length > 1 ? args[1] : "all";

var root = FindBackendRoot();
var packages = ContentTool.Packages.All(root);
var selected = target == "all" ? packages : packages.Where(p => p.PackageId == target).ToList();
if (selected.Count == 0)
{
    Console.Error.WriteLine($"Unknown package '{target}'. Known: {string.Join(", ", packages.Select(p => p.PackageId))}, all");
    return 1;
}

foreach (var cfg in selected)
{
    if (command is "parse" or "build")
        ContentTool.Parser.Run(cfg);
    if (command is "package" or "build")
        ContentTool.Packager.Run(cfg);
}
return 0;

static string FindBackendRoot()
{
    var dir = new DirectoryInfo(AppContext.BaseDirectory);
    while (dir is not null)
    {
        if (Directory.Exists(Path.Combine(dir.FullName, "content")) &&
            Directory.Exists(Path.Combine(dir.FullName, "BibleMemorization.Api")))
            return dir.FullName;
        dir = dir.Parent;
    }
    throw new DirectoryNotFoundException("Could not locate the 'backend' root (needs content/ and BibleMemorization.Api/).");
}

namespace ContentTool
{
    /// <summary>Per-package configuration.</summary>
    // The packageId is the single identifier: it is the CLI target, the source folder,
    // the content folder and the artifact folder. Its cb-/bq- prefix already encodes
    // program+language, so es/en variants never collide (cb-daniel-7-12 vs bq-daniel-7-12).
    sealed record PackageCfg(
        string PackageId, string Title, string Abbrev, string Attribution,
        string? BookTitle, string Version, string PackageType, string Language)
    {
        public required string BackendRoot { get; init; }
        public string SourcePath => Path.Combine(BackendRoot, "content", PackageId, "source.txt");
        public string ContentDir => Path.Combine(BackendRoot, "content", PackageId, "content");
        public string OutDir => Path.Combine(BackendRoot, "BibleMemorization.Api", "wwwroot", "packages", PackageId, Version);
    }

    static class Packages
    {
        public static List<PackageCfg> All(string backendRoot) =>
        [
            new("cb-daniel-1-6",  "CB Daniel 1-6",  "Dan", "REINA-VALERA 1960", "DANIEL", "1.0.0", "book", "es") { BackendRoot = backendRoot },
            new("cb-daniel-7-12", "CB Daniel 7-12", "Dan", "REINA-VALERA 1960", null,     "1.0.0", "book", "es") { BackendRoot = backendRoot },
            new("cb-hechos-1-9",  "CB Hechos 1-9",  "Hch", "REINA-VALERA 1960", "HECHOS", "1.0.0", "book", "es") { BackendRoot = backendRoot },
            new("bq-acts-1-9",    "BQ Acts 1-9",    "Acts", "KING JAMES VERSION", null,   "1.1.0", "book", "en") { BackendRoot = backendRoot },
        ];
    }

    sealed class Verse
    {
        public int Chapter;
        public int Number;
        public string Text = "";                            // may embed [[section:...]] markers
        public string? StartTitle;                          // section that begins at the start of this verse
        public List<string> MidTitles = new();              // sections that begin mid-verse, left-to-right
    }

    static class JsonFile
    {
        static readonly System.Text.Json.JsonSerializerOptions Options = new()
        {
            WriteIndented = true,
            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        };

        public static string ToText(JsonNode node) => node.ToJsonString(Options) + "\n";

        public static void Write(string path, JsonNode node) =>
            File.WriteAllText(path, ToText(node), new UTF8Encoding(false));
    }

    static class Parser
    {
        static readonly Regex OnlyNumber = new(@"^\d+$");
        static readonly Regex ChapterWord = new(@"^CHAPTER\s+(\d+)$", RegexOptions.IgnoreCase);
        static readonly Regex ParenRef = new(@"^\(.*\)$");
        static readonly Regex HasDigit = new(@"\d");
        static readonly Regex SplitDigits = new(@"(\d+)");
        static readonly Regex Whitespace = new(@"\s+");
        static readonly Regex InlineTitle = new(@"\{\{(.+?)\}\}");   // "{{Title}}" -> mid-verse section start

        public static void Run(PackageCfg cfg)
        {
            var verses = ParseVerses(cfg, out var chapterOrder);

            var chaptersDir = Path.Combine(cfg.ContentDir, "chapters");
            Directory.CreateDirectory(chaptersDir);

            // Load existing analysis data from chapter files (if any) to preserve it
            var existingAnalysis = LoadExistingAnalysis(chaptersDir, cfg.Abbrev);

            var counts = new Dictionary<int, int>();
            var problems = new List<string>();
            foreach (var ch in chapterOrder)
            {
                var cv = verses.Where(v => v.Chapter == ch).ToList();
                var nums = cv.Select(v => v.Number).ToList();
                if (!nums.SequenceEqual(Enumerable.Range(1, nums.Count)))
                    problems.Add($"ch{ch}: [{string.Join(",", nums)}]");
                counts[ch] = cv.Count;

                var arr = new JsonArray();
                foreach (var v in cv)
                {
                    var verseObj = new JsonObject
                    {
                        ["verseRef"] = $"{cfg.Abbrev} {ch}:{v.Number}",
                        ["verseNumber"] = v.Number,
                        ["text"] = v.Text,   // section titles, when present, are embedded here as markers
                    };

                    // Preserve existing analysis data if present
                    var verseKey = $"{cfg.Abbrev} {ch}:{v.Number}";
                    if (existingAnalysis.TryGetValue(verseKey, out var analysis))
                    {
                        verseObj["analysis"] = analysis;
                    }

                    arr.Add(verseObj);
                }
                JsonFile.Write(Path.Combine(chaptersDir, $"{ch:D3}.json"),
                    new JsonObject { ["chapterNumber"] = ch, ["verses"] = arr });
            }

            // sections.json — the single source of truth for section membership. A verse belongs
            // to whichever section is "active" over it; when a section starts mid-verse, that whole
            // verse belongs to BOTH the outgoing and the incoming section (overlap is intentional).
            // Packages without any section titles produce an empty list.
            var order = new List<string>();                        // section ids, first-seen order
            var titleOf = new Dictionary<string, string>();
            var refsOf = new Dictionary<string, List<string>>();
            string? active = null;

            void Register(string sid, string title)
            {
                if (refsOf.ContainsKey(sid)) return;
                order.Add(sid);
                titleOf[sid] = title;
                refsOf[sid] = new List<string>();
            }
            void AddRef(string sid, string reference)
            {
                var list = refsOf[sid];
                if (list.Count == 0 || list[^1] != reference) list.Add(reference);
            }

            foreach (var v in verses)
            {
                var reference = $"{cfg.Abbrev} {v.Chapter}:{v.Number}";
                if (v.StartTitle is not null)
                {
                    var sid = Slug(v.StartTitle)!;
                    Register(sid, v.StartTitle);
                    active = sid;                                  // clean switch at the verse start
                }
                if (active is not null) AddRef(active, reference); // the whole verse belongs to the active section
                foreach (var mid in v.MidTitles)
                {
                    var sid = Slug(mid)!;
                    Register(sid, mid);
                    AddRef(sid, reference);                        // overlap: the whole verse also belongs here
                    active = sid;                                  // subsequent verses belong to the mid section
                }
            }

            var sections = new JsonArray();
            foreach (var sid in order)
            {
                var refs = refsOf[sid];
                var refsArr = new JsonArray();
                foreach (var r in refs) refsArr.Add(r);
                sections.Add(new JsonObject
                {
                    ["sectionId"] = sid,
                    ["title"] = titleOf[sid],
                    ["startVerseRef"] = refs[0],
                    ["endVerseRef"] = refs[^1],
                    ["verseRefs"] = refsArr,
                });
            }
            JsonFile.Write(Path.Combine(cfg.ContentDir, "sections.json"),
                new JsonObject { ["packageId"] = cfg.PackageId, ["sections"] = sections });

            // index.json
            var chapterOrderArr = new JsonArray();
            foreach (var ch in chapterOrder) chapterOrderArr.Add(ch);
            var countsObj = new JsonObject();
            foreach (var ch in chapterOrder) countsObj[ch.ToString()] = counts[ch];

            // Check if any verse has analysis data
            var hasAnalysis = existingAnalysis.Count > 0;

            JsonFile.Write(Path.Combine(cfg.ContentDir, "index.json"), new JsonObject
            {
                ["packageId"] = cfg.PackageId,
                ["abbreviation"] = cfg.Abbrev,
                ["attribution"] = cfg.Attribution,
                ["chapterOrder"] = chapterOrderArr,
                ["chapterVerseCounts"] = countsObj,
                ["availableSections"] = sections.Count > 0,
                ["availableAnalysis"] = hasAnalysis,
                ["availableAudio"] = false,
            });

            Console.WriteLine($"[parse] {cfg.PackageId}: chapters {string.Join(",", chapterOrder)} | " +
                              $"verses {counts.Values.Sum()} | sections {sections.Count} | " +
                              $"problems {(problems.Count == 0 ? "none" : string.Join("; ", problems))}");
        }

        static List<Verse> ParseVerses(PackageCfg cfg, out List<int> chapterOrder)
        {
            var verses = new List<Verse>();
            chapterOrder = new List<int>();
            int? currentChapter = null;
            string? pendingTitle = null;   // standalone title waiting to attach to the next verse
            var prevBlank = true;

            foreach (var rawLine in File.ReadAllText(cfg.SourcePath).Split('\n'))
            {
                // Drop footnote markers and zero-width characters (BOM / zero-width space
                // that leak in from OCR/image extraction).
                var line = rawLine.Replace("*", "").Replace("﻿", "").Replace("​", "").Trim();
                if (line.Length == 0) { prevBlank = true; continue; }
                if (cfg.BookTitle is not null && line == cfg.BookTitle) { prevBlank = false; continue; }
                // Skip the source-attribution line (Spanish RV1960 or English KJV citation).
                if (line.StartsWith("reina valera", StringComparison.OrdinalIgnoreCase) ||
                    line.StartsWith("the holy bible", StringComparison.OrdinalIgnoreCase)) { prevBlank = false; continue; }
                if (ParenRef.IsMatch(line)) { prevBlank = false; continue; }
                var chapterMatch = ChapterWord.Match(line);
                if (OnlyNumber.IsMatch(line) || chapterMatch.Success)   // "7" (es) or "CHAPTER 7" (en)
                {
                    currentChapter = chapterMatch.Success ? int.Parse(chapterMatch.Groups[1].Value) : int.Parse(line);
                    if (!chapterOrder.Contains(currentChapter.Value)) chapterOrder.Add(currentChapter.Value);
                    prevBlank = false;
                    continue;
                }

                if (!HasDigit.IsMatch(line))
                {
                    // No verse number: a standalone section title (after a blank), or a poetry
                    // continuation of the previous verse (which may itself carry a mid-verse title).
                    if (prevBlank && !InlineTitle.IsMatch(line))
                        pendingTitle = line;
                    else if (verses.Count > 0)
                        verses[^1].Text += " " + AbsorbInlineTitles(line, verses[^1]);
                    prevBlank = false;
                    continue;
                }

                // verse-content line
                var parts = SplitDigits.Split(line);
                var lead = parts[0].Trim();
                if (lead.Length > 0 && verses.Count > 0)
                    verses[^1].Text += " " + AbsorbInlineTitles(lead, verses[^1]);
                for (var i = 1; i < parts.Length; i += 2)
                {
                    var num = int.Parse(parts[i]);
                    var raw = i + 1 < parts.Length ? parts[i + 1] : "";
                    var v = new Verse { Chapter = currentChapter!.Value, Number = num };
                    var body = AbsorbInlineTitles(raw, v);   // mid-verse titles (if any) attach to this verse
                    if (pendingTitle is not null)
                    {
                        v.StartTitle = pendingTitle;
                        v.Text = Marker(Slug(pendingTitle)!, pendingTitle) + " " + body;
                        pendingTitle = null;
                    }
                    else
                    {
                        v.Text = body;
                    }
                    verses.Add(v);
                }
                prevBlank = false;
            }

            foreach (var v in verses) v.Text = Whitespace.Replace(v.Text, " ").Trim();
            return verses;
        }

        // Replaces each "{{Title}}" in the fragment with a "[[section:id|Title]]" marker and
        // records the title as a mid-verse section start on the target verse (left-to-right).
        static string AbsorbInlineTitles(string fragment, Verse target) =>
            InlineTitle.Replace(fragment, m =>
            {
                var title = m.Groups[1].Value.Trim();
                target.MidTitles.Add(title);
                return Marker(Slug(title)!, title);
            });

        static string Marker(string sectionId, string title) => $"[[section:{sectionId}|{title}]]";

        static string? Slug(string? title)
        {
            if (string.IsNullOrEmpty(title)) return null;
            var sb = new StringBuilder();
            foreach (var c in title.Normalize(NormalizationForm.FormD))
                if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                    sb.Append(c);
            var s = sb.ToString().ToLowerInvariant();
            s = Regex.Replace(s, "[^a-z0-9]+", "-").Trim('-');
            return s;
        }

        /// <summary>
        /// Loads existing analysis data from chapter JSON files to preserve them during re-parse.
        /// Returns a map of verseRef -> analysis JsonNode.
        /// </summary>
        static Dictionary<string, JsonNode> LoadExistingAnalysis(string chaptersDir, string abbrev)
        {
            var result = new Dictionary<string, JsonNode>();

            if (!Directory.Exists(chaptersDir))
                return result;

            foreach (var file in Directory.GetFiles(chaptersDir, "*.json"))
            {
                try
                {
                    var content = File.ReadAllText(file);
                    var node = JsonNode.Parse(content);
                    var verses = node?["verses"]?.AsArray();

                    if (verses is null)
                        continue;

                    foreach (var verse in verses)
                    {
                        var verseRef = verse?["verseRef"]?.GetValue<string>();
                        var analysis = verse?["analysis"];

                        if (verseRef is not null && analysis is not null)
                        {
                            result[verseRef] = analysis.DeepClone();
                        }
                    }
                }
                catch
                {
                    // Skip files that can't be parsed (might be corrupt or new format)
                }
            }

            return result;
        }
    }

    static class Packager
    {
        static readonly DateTimeOffset FixedTime = new(2026, 7, 22, 0, 0, 0, TimeSpan.Zero);
        const string CreatedAt = "2026-07-22T00:00:00Z";

        public static void Run(PackageCfg cfg)
        {
            Directory.CreateDirectory(cfg.OutDir);

            var files = Directory.GetFiles(cfg.ContentDir, "*", SearchOption.AllDirectories)
                .Select(p => (Arc: "content/" + Path.GetRelativePath(cfg.ContentDir, p).Replace('\\', '/'), Data: File.ReadAllBytes(p)))
                .OrderBy(x => x.Arc, StringComparer.Ordinal)
                .ToList();

            var index = JsonNode.Parse(File.ReadAllText(Path.Combine(cfg.ContentDir, "index.json")))!;
            var counts = index["chapterVerseCounts"]!.AsObject();
            var verseCount = counts.Sum(kv => kv.Value!.GetValue<int>());
            var chapterCount = index["chapterOrder"]!.AsArray().Count;

            var filesMeta = new JsonArray();
            foreach (var (arc, data) in files)
                filesMeta.Add(new JsonObject
                {
                    ["path"] = arc,
                    ["sizeBytes"] = data.Length,
                    ["checksumSha256"] = Sha256Hex(data),
                    ["required"] = arc == "content/index.json" || arc.StartsWith("content/chapters/"),
                });

            var manifest = new JsonObject
            {
                ["packageId"] = cfg.PackageId,
                ["title"] = cfg.Title,
                ["packageType"] = cfg.PackageType,
                ["language"] = cfg.Language,
                ["version"] = cfg.Version,
                ["schemaVersion"] = 1,
                ["minAppVersion"] = "1.0.0",
                ["attribution"] = cfg.Attribution,
                ["createdAt"] = CreatedAt,
                ["verseCount"] = verseCount,
                ["chapterCount"] = chapterCount,
                ["files"] = filesMeta,
            };
            var manifestBytes = Encoding.UTF8.GetBytes(JsonFile.ToText(manifest));
            File.WriteAllBytes(Path.Combine(cfg.OutDir, "manifest.json"), manifestBytes);

            var zipPath = Path.Combine(cfg.OutDir, "package.zip");
            if (File.Exists(zipPath)) File.Delete(zipPath);
            using (var fs = new FileStream(zipPath, FileMode.Create))
            using (var zip = new ZipArchive(fs, ZipArchiveMode.Create))
            {
                var entries = new List<(string Arc, byte[] Data)> { ("manifest.json", manifestBytes) };
                entries.AddRange(files);
                foreach (var (arc, data) in entries)
                {
                    var entry = zip.CreateEntry(arc, CompressionLevel.Optimal);
                    entry.LastWriteTime = FixedTime;
                    using var es = entry.Open();
                    es.Write(data, 0, data.Length);
                }
            }

            var zipBytes = File.ReadAllBytes(zipPath);
            var zipHash = Sha256Hex(zipBytes);
            File.WriteAllText(Path.Combine(cfg.OutDir, "package.sha256"), zipHash + "\n", new UTF8Encoding(false));

            Console.WriteLine($"[package] {cfg.PackageId}: package.zip {zipBytes.Length} bytes | sha256 {zipHash} | " +
                              $"verses {verseCount} | chapters {chapterCount} | files {filesMeta.Count}");
        }

        static string Sha256Hex(byte[] data) => Convert.ToHexString(SHA256.HashData(data)).ToLowerInvariant();
    }
}
