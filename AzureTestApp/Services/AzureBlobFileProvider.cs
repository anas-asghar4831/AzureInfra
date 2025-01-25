using Azure.Storage.Blobs;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Primitives;
using System.IO;

public class AzureBlobFileProvider : IFileProvider
{
    private readonly BlobContainerClient _blobContainerClient;

    public AzureBlobFileProvider(string connectionString, string containerName)
    {
        _blobContainerClient = new BlobServiceClient(connectionString).GetBlobContainerClient(containerName);
    }

    public IDirectoryContents GetDirectoryContents(string subpath)
    {
        // Azure Blob Storage doesn't support directory browsing
        return NotFoundDirectoryContents.Singleton;
    }

    public IFileInfo GetFileInfo(string subpath)
    {
        var blobClient = _blobContainerClient.GetBlobClient(subpath.TrimStart('/'));
        return blobClient.Exists() ? new AzureBlobFileInfo(blobClient) : new NotFoundFileInfo(subpath);
    }

    public IChangeToken Watch(string filter)
    {
        // Azure Blob Storage doesn't support change monitoring
        return NullChangeToken.Singleton;
    }
}
