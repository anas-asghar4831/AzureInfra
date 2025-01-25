using Azure.Storage.Blobs;
using Microsoft.Extensions.FileProviders;
using System.IO;

public class AzureBlobFileInfo : IFileInfo
{
    private readonly BlobClient _blobClient;

    public AzureBlobFileInfo(BlobClient blobClient)
    {
        _blobClient = blobClient;
    }

    public bool Exists => _blobClient.Exists();

    public long Length => _blobClient.GetProperties().Value.ContentLength;

    public string? PhysicalPath => null;

    public string Name => Path.GetFileName(_blobClient.Name);

    public DateTimeOffset LastModified => _blobClient.GetProperties().Value.LastModified;

    public bool IsDirectory => false;

    public Stream CreateReadStream()
    {
        return _blobClient.OpenRead();
    }
}
