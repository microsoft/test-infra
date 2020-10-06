# Introduction 
This is used to setup and manage a scaling Jenkins service using the Azure Kubernetes Service via Azure CLI.

Image: Jenkins LTS
Ingress: Nginx
Configuration: Managed by Jenkins Configuration as Code Plugin
Credentials: Jenkins + Azure Key Vault
Storage: Azure Persistent Volumes

# Getting Started
## Installation process
1. Open aks-cluster-deploy.sh, jenkins-install-plugins.sh, and jenkins-install-configuration.sh scripts and change variables specific to your needs. Detailed instructions are written in-script.
2. Add executable permissions by running: `chmod +x aks-cluster-deploy.sh jenkins-install-plugins.sh jenkins-install-configuration.sh`
3. Log in to Azure by running: `az login`
4. Set up AKS cluster by running: `./aks-cluster-deploy.sh`
5. Install Jenkins plugins by running: `./jenkins-install-plugins.sh`. When this is complete, a new Kubernetes pod will be started. If the new pod can start Jenkins successfully, which takes about 5 - 10 minutes, the old pod will be terminated.
6. Install Jenkins configuration by running: `./jenkins-install-configuration.sh`. Configuration can be picked up by restarting Jenkins (during a new Jenkins setup) or by running the 'Master/reload-configuration' job on Jenkins.

## Dependencies
### Azure resource requirements
* A new Azure Service Principal
* An existing Azure Key Vault

### Azure Service Principal Permissions:
* User to modify the password of the Service Principal
* Service Principal needs read-only access to the specified Key Vault
* Service Principal needs read-only access to Image Gallery specified (For VM Agents plugin)
* Service Principal needs contributor access to Storage account specified (For VM Agents plugin)

## Updating Jenkin Plugins
1. Update the plugins list in jenkins-install-plugins.sh to include the url to the direct plugin (.hpi or .jpi). Ensure any dependencies of your new plugin are also added as this script does not automatically resolve dependencies.
2. Run jenkins-install-plugins.sh (refer to installation process for more information).

## Updating Jenkins Configuration
1. Update `configuration/jenkins.yml` or if you want to keep it separate from core configuration you can add a new YAML file in `configuration/`.
2. Configuration changes can be picked up by restarting Jenkins (during a new Jenkins setup) or by running the 'Master/reload-configuration' job on Jenkins.

_For more information, see https://github.com/jenkinsci/configuration-as-code-plugin_ 

## Updating Jenkins Jobs
1. Update the relevant job in `configuration/jobs/` or add your own job. The jobs shown in this directory uses the [job-dsl-plugin](https://plugins.jenkins.io/job-dsl/) which is usually made up of a combination of YAML, Groovy, Jenkins Pipeline syntax. For examples, see [the demos from Jenkins CasC](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos/jobs).

_Job DSL API Reference: https://jenkinsci.github.io/job-dsl-plugin/_

## References
### Azure
Azure Key Vault: https://docs.microsoft.com/en-us/azure/key-vault/
Azure Kubernetes Service: https://docs.microsoft.com/en-us/azure/aks/

### Jenkins
Jenkins LTS: https://www.jenkins.io/changelog-stable/
Jenkins Configuration as Code: https://github.com/jenkinsci/configuration-as-code-plugin
Jenkins Job DSL API Reference: https://jenkinsci.github.io/job-dsl-plugin/ 
