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
        ];
    }

    sealed class Verse
    {
        public int Chapter;
        public int Number;
        public string Text = "";
        public string? Title;
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
        static readonly Regex ParenRef = new(@"^\(.*\)$");
        static readonly Regex HasDigit = new(@"\d");
        static readonly Regex SplitDigits = new(@"(\d+)");
        static readonly Regex Whitespace = new(@"\s+");

        public static void Run(PackageCfg cfg)
        {
            var verses = ParseVerses(cfg, out var chapterOrder);

            var chaptersDir = Path.Combine(cfg.ContentDir, "chapters");
            Directory.CreateDirectory(chaptersDir);

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
                    arr.Add(new JsonObject
                    {
                        ["verseRef"] = $"{cfg.Abbrev} {ch}:{v.Number}",
                        ["verseNumber"] = v.Number,
                        ["text"] = v.Text,
                        ["sectionId"] = Slug(v.Title),
                    });
                JsonFile.Write(Path.Combine(chaptersDir, $"{ch:D3}.json"),
                    new JsonObject { ["chapterNumber"] = ch, ["verses"] = arr });
            }

            // sections.json — group consecutive verses by section.
            var sections = new JsonArray();
            JsonObject? current = null;
            string? currentSid = null;
            var started = false;
            foreach (var v in verses)
            {
                var reference = $"{cfg.Abbrev} {v.Chapter}:{v.Number}";
                var sid = Slug(v.Title);
                if (!started || sid != currentSid)
                {
                    current = new JsonObject
                    {
                        ["sectionId"] = sid,
                        ["title"] = v.Title,
                        ["startVerseRef"] = reference,
                        ["endVerseRef"] = reference,
                        ["verseRefs"] = new JsonArray(reference),
                    };
                    sections.Add(current);
                    currentSid = sid;
                    started = true;
                }
                else
                {
                    current!["endVerseRef"] = reference;
                    ((JsonArray)current["verseRefs"]!).Add(reference);
                }
            }
            JsonFile.Write(Path.Combine(cfg.ContentDir, "sections.json"),
                new JsonObject { ["packageId"] = cfg.PackageId, ["sections"] = sections });

            // index.json
            var chapterOrderArr = new JsonArray();
            foreach (var ch in chapterOrder) chapterOrderArr.Add(ch);
            var countsObj = new JsonObject();
            foreach (var ch in chapterOrder) countsObj[ch.ToString()] = counts[ch];
            JsonFile.Write(Path.Combine(cfg.ContentDir, "index.json"), new JsonObject
            {
                ["packageId"] = cfg.PackageId,
                ["abbreviation"] = cfg.Abbrev,
                ["attribution"] = cfg.Attribution,
                ["chapterOrder"] = chapterOrderArr,
                ["chapterVerseCounts"] = countsObj,
                ["availableSections"] = true,
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
            string? currentTitle = null;
            var prevBlank = true;

            foreach (var rawLine in File.ReadAllText(cfg.SourcePath).Split('\n'))
            {
                var line = rawLine.Replace("*", "").Trim();
                if (line.Length == 0) { prevBlank = true; continue; }
                if (cfg.BookTitle is not null && line == cfg.BookTitle) { prevBlank = false; continue; }
                if (line.StartsWith("reina valera", StringComparison.OrdinalIgnoreCase)) { prevBlank = false; continue; }
                if (ParenRef.IsMatch(line)) { prevBlank = false; continue; }
                if (OnlyNumber.IsMatch(line))
                {
                    currentChapter = int.Parse(line);
                    if (!chapterOrder.Contains(currentChapter.Value)) chapterOrder.Add(currentChapter.Value);
                    prevBlank = false;
                    continue;
                }

                if (!HasDigit.IsMatch(line))
                {
                    if (prevBlank) currentTitle = line;
                    else if (verses.Count > 0) verses[^1].Text += " " + line;
                    prevBlank = false;
                    continue;
                }

                // verse-content line
                var parts = SplitDigits.Split(line);
                var lead = parts[0].Trim();
                if (lead.Length > 0 && verses.Count > 0) verses[^1].Text += " " + lead;
                for (var i = 1; i < parts.Length; i += 2)
                {
                    var num = int.Parse(parts[i]);
                    var vtext = i + 1 < parts.Length ? parts[i + 1] : "";
                    verses.Add(new Verse { Chapter = currentChapter!.Value, Number = num, Text = vtext, Title = currentTitle });
                }
                prevBlank = false;
            }

            foreach (var v in verses) v.Text = Whitespace.Replace(v.Text, " ").Trim();
            return verses;
        }

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
