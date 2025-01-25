const { app } = require('@azure/functions');
const fs = require('fs');
const { exec } = require('child_process');
const path = require('path');
const os = require('os');

// Function to check if a package is installed
function isMermaidCliInstalled(callback) {
    exec('npx --no-install mmdc -v', (error, stdout, stderr) => {
        if (error) {
            callback(false);
        } else {
            callback(true);
        }
    });
}

// Function to install Mermaid CLI
function installMermaidCli(callback) {
    console.log('Mermaid CLI not found. Installing...');
    exec('npm install @mermaid-js/mermaid-cli', (error, stdout, stderr) => {
        if (error) {
            console.error(`Failed to install Mermaid CLI: ${error.message}`);
            process.exit(1);
        }
        console.log('Mermaid CLI installed successfully.');
        callback();
    });
}

// Function to convert .mmd file to PNG
function convertMmdToPng(inputFile, outputFile, context, callback) {
    const mermaidCommand = 'npx mmdc'; // npx will use the locally installed Mermaid CLI or download it temporarily

    // Construct the Mermaid CLI command
    const command = `${mermaidCommand} -i "${inputFile}" -o "${outputFile}"`;

    // Execute the command
    exec(command, (error, stdout, stderr) => {
        if (error) {
            context.log(`Error: ${error.message}`);
            callback(error);
            return;
        }

        if (stderr) {
            context.log(`stderr: ${stderr}`);
        }

        context.log(`Mermaid diagram converted to PNG: ${outputFile}`);
        callback(null, outputFile);
    });
}

app.http('mmdTOpng', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log(`Http function processed request for url "${request.url}"`);

        const boundary = os.tmpdir();
        const inputFilePath = path.join(boundary, `input-${Date.now()}.mmd`);
        const outputFilePath = path.join(boundary, `output-${Date.now()}.png`);

        const fileBuffer = await request.arrayBuffer();
        fs.writeFileSync(inputFilePath, Buffer.from(fileBuffer));

        return new Promise((resolve) => {
            isMermaidCliInstalled((isInstalled) => {
                if (!isInstalled) {
                    installMermaidCli(() => {
                        convertMmdToPng(inputFilePath, outputFilePath, context, (error, outputFile) => {
                            if (error) {
                                resolve({ status: 500, body: 'Failed to convert .mmd to PNG.' });
                                return;
                            }

                            const imageBuffer = fs.readFileSync(outputFile);
                            resolve({
                                status: 200,
                                headers: {
                                    'Content-Type': 'image/png',
                                },
                                body: imageBuffer,
                            });

                            // Cleanup temporary files
                            fs.unlinkSync(inputFilePath);
                            fs.unlinkSync(outputFilePath);
                        });
                    });
                } else {
                    convertMmdToPng(inputFilePath, outputFilePath, context, (error, outputFile) => {
                        if (error) {
                            resolve({ status: 500, body: 'Failed to convert .mmd to PNG.' });
                            return;
                        }

                        const imageBuffer = fs.readFileSync(outputFile);
                        resolve({
                            status: 200,
                            headers: {
                                'Content-Type': 'image/png',
                            },
                            body: imageBuffer,
                        });

                        // Cleanup temporary files
                        fs.unlinkSync(inputFilePath);
                        fs.unlinkSync(outputFilePath);
                    });
                }
            });
        });
    },
});
