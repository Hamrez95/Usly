var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();

var app = builder.Build();

app.UseExceptionHandler();
app.UseHttpsRedirection();

app.MapGet("/", () => Results.Ok(new
{
    service = "Usly.Api",
    status = "foundation",
    message = "Usly product development is gated by validation milestones."
}));

app.MapHealthChecks("/health");

app.Run();

public partial class Program;
