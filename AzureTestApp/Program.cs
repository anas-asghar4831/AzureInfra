using Azure.Storage.Blobs;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

builder.Services.AddSingleton<IFileProvider>(provider =>
{
    var connectionString = builder.Configuration["AzureBlob:ConnectionString"] ?? "";
    var containerName = builder.Configuration["AzureBlob:ContainerName"] ?? "";
    return new AzureBlobFileProvider(connectionString, containerName);
});

var app = builder.Build();

app.UseHttpsRedirection();

var fileProvider = app.Services.GetRequiredService<IFileProvider>();
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = fileProvider,
    RequestPath = ""
});

app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
