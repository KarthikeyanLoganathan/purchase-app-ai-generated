const deployer = {
  /**
   * deployer.js
   * Handles deployment of the Google Apps Script web app
   */

  /**
   * Main deployment function
   * Uses Apps Script API to manage deployments
   * Note: Requires "Google Apps Script API" to be enabled in Advanced Services
   */
  deployWebApp() {
    try {
      const scriptId = ScriptApp.getScriptId();

      // Check if Apps Script API is available
      // @ts-ignore - Script service is available when Apps Script API is enabled
      if (typeof Script === 'undefined') {
        this.showManualDeploymentInstructions();
        return;
      }

      // Archive existing deployments
      this.archiveExistingDeployments();

      // Create new deployment
      const webAppUrl = this.createNewDeployment();

      // Update config sheet with URL
      this.updateConfigSheetWithUrl(webAppUrl);

      // Show URL in popup for easy copying
      this.showUrlInPopup(webAppUrl);
      return webAppUrl;
    } catch (error) {
      Logger.log('Deployment error: ' + error.toString());
      const execContext = utils.getExecutionContext();
      if (execContext.canShowAlert) {
        SpreadsheetApp.getUi().alert('Deployment Failed',
          'Error: ' + error.toString() + '\n\nMake sure "Google Apps Script API" is enabled in Services.',
          SpreadsheetApp.getUi().ButtonSet.OK);
      }
      throw error;
    }
  },

  /**
   * Archives all active deployments for the current script
   */
  archiveExistingDeployments() {
    try {
      const scriptId = ScriptApp.getScriptId();

      // Get all deployments using Apps Script API
      // @ts-ignore - Script service is available when Apps Script API is enabled
      const deployments = Script.Projects.Deployments.list(scriptId).deployments || [];

      let archivedCount = 0;
      deployments.forEach(function (deployment) {
        const deploymentId = deployment.deploymentId;

        // Only update non-versioned deployments (HEAD deployments are auto-managed)
        if (deploymentId && deploymentId !== '@HEAD') {
          try {
            const updateBody = {
              deploymentConfig: {
                description: '[ARCHIVED] ' + (deployment.deploymentConfig.description || 'Previous deployment')
              }
            };

            Script.Projects.Deployments.update(updateBody, scriptId, deploymentId);
            archivedCount++;
            Logger.log('Archived deployment: ' + deploymentId);
          } catch (e) {
            Logger.log('Could not archive deployment ' + deploymentId + ': ' + e.toString());
          }
        }
      });

      Logger.log('Archived ' + archivedCount + ' deployment(s)');
    } catch (error) {
      Logger.log('Error archiving deployments: ' + error.toString());
      // Continue with deployment even if archiving fails
    }
  },

  /**
   * Creates a new web app deployment using Apps Script API
   * @returns {string} The web app URL
   */
  createNewDeployment() {
    try {
      const scriptId = ScriptApp.getScriptId();

      // Create a new version first
      const versionDescription = 'Web App Version - ' + new Date().toISOString();
      // @ts-ignore - Script service is available when Apps Script API is enabled
      const version = Script.Projects.Versions.create({
        description: versionDescription
      }, scriptId);

      const versionNumber = version.versionNumber;
      Logger.log('Created version: ' + versionNumber);

      // Create deployment configuration
      const deploymentBody = {
        versionNumber: versionNumber,
        manifestFileName: 'appsscript',
        description: 'Web App Deployment - ' + new Date().toISOString()
      };

      // @ts-ignore - Script service is available when Apps Script API is enabled
      // Create the deployment
      const deployment = Script.Projects.Deployments.create({
        deploymentConfig: deploymentBody
      }, scriptId);

      // Get the web app URL from entry points
      let webAppUrl = null;
      if (deployment.entryPoints) {
        for (let i = 0; i < deployment.entryPoints.length; i++) {
          if (deployment.entryPoints[i].entryPointType === 'WEB_APP' &&
            deployment.entryPoints[i].webApp) {
            webAppUrl = deployment.entryPoints[i].webApp.url;
            break;
          }
        }
      }

      if (!webAppUrl) {
        throw new Error('No web app URL found in deployment response');
      }

      Logger.log('New deployment created: ' + webAppUrl);
      return webAppUrl;

    } catch (error) {
      Logger.log('Error creating deployment: ' + error.toString());
      throw new Error('Failed to create deployment: ' + error.toString());
    }
  },

  /**
   * Updates the config sheet with the web app URL at cell (3,2)
   * @param {string} url - The web app URL to save
   */
  updateConfigSheetWithUrl(url) {
    try {
      const ss = SpreadsheetApp.getActiveSpreadsheet();
      const configSheet = ss.getSheetByName('config');

      if (!configSheet) {
        Logger.log('Warning: config sheet not found');
        return;
      }

      // Set URL at cell (3,2) - row 3, column 2
      configSheet.getRange(3, 2).setValue(url);
      Logger.log('Updated config sheet cell (3,2) with URL');
    } catch (error) {
      Logger.log('Error updating config sheet: ' + error.toString());
      // Don't throw - deployment succeeded even if sheet update fails
    }
  },

  /**
   * Shows the web app URL in a popup dialog for easy copying
   * @param {string} url - The web app URL to display
   */
  showUrlInPopup(url) {
    const execContext = utils.getExecutionContext();
    try {
      const html = HtmlService.createHtmlOutput(`
      <!DOCTYPE html>
      <html>
        <head>
          <base target="_top">
          <style>
            body {
              font-family: Arial, sans-serif;
              padding: 20px;
              margin: 0;
            }
            h2 {
              color: #1a73e8;
              margin-top: 0;
            }
            .url-container {
              margin: 20px 0;
            }
            #urlTextBox {
              width: 100%;
              padding: 10px;
              font-family: monospace;
              font-size: 12px;
              border: 1px solid #dadce0;
              border-radius: 4px;
              box-sizing: border-box;
            }
            .button-container {
              margin-top: 15px;
              text-align: center;
            }
            button {
              background-color: #1a73e8;
              color: white;
              border: none;
              padding: 10px 24px;
              font-size: 14px;
              border-radius: 4px;
              cursor: pointer;
              margin: 0 5px;
            }
            button:hover {
              background-color: #1557b0;
            }
            .success-message {
              color: #137333;
              margin-top: 10px;
              display: none;
            }
          </style>
        </head>
        <body>
          <h2>🚀 Deployment Successful!</h2>
          <p>Your web app has been deployed. Copy the URL below:</p>
          
          <div class="url-container">
            <input type="text" id="urlTextBox" value="${url}" readonly onclick="this.select()">
          </div>
          
          <div class="button-container">
            <button onclick="copyToClipboard()">📋 Copy to Clipboard</button>
            <button onclick="openUrl()">🔗 Open URL</button>
          </div>
          
          <div id="successMessage" class="success-message">
            ✓ Copied to clipboard!
          </div>
          
          <script>
            function copyToClipboard() {
              const textBox = document.getElementById('urlTextBox');
              textBox.select();
              textBox.setSelectionRange(0, 99999); // For mobile devices
              
              try {
                document.execCommand('copy');
                showSuccess();
              } catch (err) {
                // Fallback for modern browsers
                navigator.clipboard.writeText(textBox.value).then(
                  function() { showSuccess(); },
                  function(err) { alert('Failed to copy: ' + err); }
                );
              }
            }
            
            function showSuccess() {
              const msg = document.getElementById('successMessage');
              msg.style.display = 'block';
              setTimeout(function() {
                msg.style.display = 'none';
              }, 2000);
            }
            
            function openUrl() {
              window.open('${url}', '_blank');
            }
            
            // Auto-select text when dialog opens
            window.onload = function() {
              document.getElementById('urlTextBox').select();
            };
          </script>
        </body>
      </html>
    `)
        .setWidth(600)
        .setHeight(280);

      if (execContext.canShowAlert) {
        SpreadsheetApp.getUi().showModalDialog(html, 'Web App Deployed');
      }
    } catch (error) {
      Logger.log('Error showing popup: ' + error.toString());
      // Fallback to simple alert
      if (execContext.canShowAlert) {
        SpreadsheetApp.getUi().alert(
          'Deployment Successful!',
          'Web App URL:\n\n' + url,
          SpreadsheetApp.getUi().ButtonSet.OK
        );
      }
    }
  },

  /**
   * Shows manual deployment instructions when API is not available
   */
  showManualDeploymentInstructions() {
    const ui = SpreadsheetApp.getUi();

    const html = HtmlService.createHtmlOutput(`
    <!DOCTYPE html>
    <html>
      <head>
        <base target="_top">
        <style>
          body {
            font-family: Arial, sans-serif;
            padding: 20px;
            line-height: 1.6;
          }
          h2 { color: #d93025; }
          h3 { color: #1a73e8; margin-top: 20px; }
          ol { padding-left: 25px; }
          li { margin: 10px 0; }
          code {
            background: #f1f3f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
          }
          .note {
            background: #fef7e0;
            border-left: 4px solid #f9ab00;
            padding: 12px;
            margin: 15px 0;
          }
        </style>
      </head>
      <body>
        <h2>⚠️ Apps Script API Not Enabled</h2>
        <p>To enable automated deployment, you need to enable the Google Apps Script API service.</p>
        
        <h3>Option 1: Enable Apps Script API (Recommended)</h3>
        <ol>
          <li>In the script editor, click on <strong>Services</strong> (+ icon on the left sidebar)</li>
          <li>Find <code>Google Apps Script API</code> in the list</li>
          <li>Click <strong>Add</strong></li>
          <li>Run <code>deployWebApp()</code> again</li>
        </ol>
        
        <h3>Option 2: Manual Deployment</h3>
        <ol>
          <li>Click <strong>Deploy</strong> → <strong>New deployment</strong></li>
          <li>Click the gear icon ⚙️ and select <strong>Web app</strong></li>
          <li>Set:
            <ul>
              <li>Execute as: <code>Me</code></li>
              <li>Who has access: <code>Anyone</code></li>
            </ul>
          </li>
          <li>Click <strong>Deploy</strong></li>
          <li>Copy the web app URL</li>
          <li>Run <code>saveDeploymentUrl("YOUR_URL_HERE")</code> to save it</li>
        </ol>
        
        <div class="note">
          <strong>Note:</strong> After manual deployment, use the <code>saveDeploymentUrl(url)</code> 
          function to update the config sheet and show the URL dialog.
        </div>
      </body>
    </html>
  `)
      .setWidth(600)
      .setHeight(500);

    ui.showModalDialog(html, 'Enable Apps Script API');
  },

  /**
   * Helper function to save a manually created deployment URL
   * @param {string} url - The web app URL from manual deployment
   */
  saveDeploymentUrl(url) {
    if (!url) {
      const execContext = utils.getExecutionContext();
      if (execContext.canShowAlert) {
        SpreadsheetApp.getUi().alert('Error', 'Please provide the deployment URL', SpreadsheetApp.getUi().ButtonSet.OK);
      }
      return;
    }

    // Update config sheet with URL
    this.updateConfigSheetWithUrl(url);

    // Show URL in popup for easy copying
    this.showUrlInPopup(url);

    Logger.log('Deployment URL saved: ' + url);
  }
}