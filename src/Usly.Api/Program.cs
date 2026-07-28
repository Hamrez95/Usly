using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddSingleton<DemoStore>();

var app = builder.Build();

app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/api/status", () => Results.Ok(new
{
    service = "Usly.Api",
    status = "initial-app",
    version = "0.1.0"
}));

app.MapGet("/api/demo", (DemoStore store) => Results.Ok(store.Snapshot()));

app.MapPost("/api/demo/reset", (DemoStore store) =>
{
    store.Reset();
    return Results.NoContent();
});

app.MapPut("/api/demo/responses/{partner}", (string partner, WeeklyResponseRequest request, DemoStore store) =>
{
    if (partner is not ("a" or "b"))
        return Results.BadRequest(new { message = "Partner must be 'a' or 'b'." });

    if (!WeeklyResponseRequest.IsValid(request))
        return Results.BadRequest(new { message = "Please complete all weekly sync fields." });

    store.SaveResponse(partner, request);
    return Results.Ok(store.Snapshot());
});

app.MapPost("/api/demo/votes/{partner}", (string partner, VoteRequest request, DemoStore store) =>
{
    if (partner is not ("a" or "b"))
        return Results.BadRequest(new { message = "Partner must be 'a' or 'b'." });

    if (request.OptionId is < 1 or > 3 || request.Value is < 0 or > 2)
        return Results.BadRequest(new { message = "Invalid vote." });

    store.SaveVote(partner, request);
    return Results.Ok(store.Snapshot());
});

app.MapPost("/api/demo/select/{optionId:int}", (int optionId, DemoStore store) =>
{
    if (optionId is < 1 or > 3)
        return Results.BadRequest(new { message = "Invalid option." });

    store.Select(optionId);
    return Results.Ok(store.Snapshot());
});

app.MapHealthChecks("/health");
app.MapFallbackToFile("index.html");

app.Run();

public partial class Program;

public sealed record WeeklyResponseRequest(
    int Energy,
    string Need,
    string Budget,
    string Duration,
    string Setting)
{
    public static bool IsValid(WeeklyResponseRequest value) =>
        value.Energy is >= 1 and <= 5 &&
        !string.IsNullOrWhiteSpace(value.Need) &&
        !string.IsNullOrWhiteSpace(value.Budget) &&
        !string.IsNullOrWhiteSpace(value.Duration) &&
        !string.IsNullOrWhiteSpace(value.Setting);
}

public sealed record VoteRequest(int OptionId, int Value);

public sealed class DemoStore
{
    private readonly object _gate = new();
    private readonly Dictionary<string, WeeklyResponseRequest> _responses = [];
    private readonly Dictionary<string, VoteRequest> _votes = [];
    private int? _selectedOptionId;

    public void SaveResponse(string partner, WeeklyResponseRequest response)
    {
        lock (_gate)
        {
            _responses[partner] = response;
            _votes.Clear();
            _selectedOptionId = null;
        }
    }

    public void SaveVote(string partner, VoteRequest vote)
    {
        lock (_gate)
        {
            _votes[partner] = vote;
        }
    }

    public void Select(int optionId)
    {
        lock (_gate)
        {
            _selectedOptionId = optionId;
        }
    }

    public void Reset()
    {
        lock (_gate)
        {
            _responses.Clear();
            _votes.Clear();
            _selectedOptionId = null;
        }
    }

    public object Snapshot()
    {
        lock (_gate)
        {
            var ready = _responses.Count == 2;
            var options = ready ? BuildOptions(_responses["a"], _responses["b"]) : [];
            var match = FindMatch(options);

            return new
            {
                responseStatus = new
                {
                    a = _responses.ContainsKey("a"),
                    b = _responses.ContainsKey("b")
                },
                ready,
                reveal = ready ? BuildReveal(_responses["a"], _responses["b"]) : null,
                options,
                voteStatus = new
                {
                    a = _votes.ContainsKey("a"),
                    b = _votes.ContainsKey("b")
                },
                match,
                selectedOptionId = _selectedOptionId
            };
        }
    }

    private object? FindMatch(List<ExperienceOption> options)
    {
        if (_votes.Count < 2) return null;

        var a = _votes["a"];
        var b = _votes["b"];
        if (a.OptionId == b.OptionId && a.Value > 0 && b.Value > 0)
            return options.First(x => x.Id == a.OptionId);

        return options
            .Select(option => new
            {
                Option = option,
                Score = _votes.Values.Where(v => v.OptionId == option.Id).Sum(v => v.Value)
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Option.Id)
            .FirstOrDefault(x => x.Score > 0)?.Option;
    }

    private static object BuildReveal(WeeklyResponseRequest a, WeeklyResponseRequest b)
    {
        var sharedNeed = a.Need == b.Need ? a.Need : "ترکیبی از خواسته‌های هر دو نفر";
        var energy = Math.Min(a.Energy, b.Energy);
        var setting = a.Setting == b.Setting ? a.Setting : "ترکیبی";

        return new
        {
            title = a.Need == b.Need ? "این هفته روی یک موج هستید" : "این هفته ترجیح‌های متفاوتی دارید",
            summary = $"پیشنهادها با تمرکز بر {sharedNeed}، انرژی سطح {energy} و فضای {setting} ساخته شدند.",
            note = "پاسخ‌های خصوصی نمایش داده نمی‌شوند؛ فقط زمینه مشترک استفاده شده است."
        };
    }

    private static List<ExperienceOption> BuildOptions(WeeklyResponseRequest a, WeeklyResponseRequest b)
    {
        var lowEnergy = Math.Min(a.Energy, b.Energy) <= 2;
        var atHome = a.Setting == "خانه" || b.Setting == "خانه";
        var shortTime = a.Duration == "۳۰ دقیقه" || b.Duration == "۳۰ دقیقه";

        return
        [
            new(1, "راحت", lowEnergy || atHome ? "کافه خانگی بدون موبایل" : "قدم‌زدن و نوشیدنی کوتاه", shortTime ? "۳۰ دقیقه" : "۴۵ دقیقه", "کم", "یک نوشیدنی آماده کنید، موبایل‌ها را کنار بگذارید و درباره بهترین بخش هفته حرف بزنید."),
            new(2, "متعادل", atHome ? "شام مشترک با پلی‌لیست دونفره" : "قرار سبک در یک کافه آرام", "۶۰ تا ۹۰ دقیقه", a.Budget == "رایگان" || b.Budget == "رایگان" ? "کم" : "متوسط", "هر نفر سه آهنگ انتخاب کند و در طول برنامه یک سؤال تازه از دیگری بپرسد."),
            new(3, "متفاوت", lowEnergy ? "بازی کشف خاطره در خانه" : "قرار با انتخاب تصادفی مسیر", "۹۰ دقیقه", "متوسط", "سه انتخاب کوچک را به شانس بسپارید: مسیر، خوراکی و یک فعالیت کوتاه. هدف، تازگی بدون فشار است.")
        ];
    }
}

public sealed record ExperienceOption(
    int Id,
    string Type,
    string Title,
    string Duration,
    string Budget,
    string Instructions);
