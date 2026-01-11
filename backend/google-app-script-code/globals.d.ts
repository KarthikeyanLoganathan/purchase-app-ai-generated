/// <reference types="google-apps-script" />

/**
 * Google Apps Script Type Definitions
 * This file helps VSCode understand Google Apps Script globals and custom symbols
 */

// Declare that all .gs.js files share a global scope
declare global {
  // Google Apps Script built-in services are already available via @types/google-apps-script
  
  /**
   * Google Apps Script Advanced Service
   * Available when "Google Apps Script API" is enabled in Services
   */
  namespace Script {
    namespace Projects {
      namespace Deployments {
        function list(scriptId: string): {
          deployments?: Array<{
            deploymentId: string;
            deploymentConfig: {
              description?: string;
              versionNumber?: number;
              manifestFileName?: string;
            };
            entryPoints?: Array<{
              entryPointType: string;
              webApp?: {
                url: string;
              };
            }>;
          }>;
        };
        
        function create(body: { deploymentConfig: any }, scriptId: string): {
          deploymentId: string;
          entryPoints?: Array<{
            entryPointType: string;
            webApp?: {
              url: string;
            };
          }>;
        };
        
        function update(body: { deploymentConfig: any }, scriptId: string, deploymentId: string): any;
      }
      
      namespace Versions {
        function create(body: { description: string }, scriptId: string): {
          versionNumber: number;
        };
      }
    }
  }
}

export {};
