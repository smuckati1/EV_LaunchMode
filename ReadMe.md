# Continuous Integration (CI) for MBD - Automate Model Testing and and Generate AUTOSAR Compliant Code
*Using automotive controllers as an example, let's learn how to effectively setup CI pipelines for Model-Based Design, and how it will benefit your team*
<br />

## Review Latest Artifacts
Download the Artifacts (Zip File) of the latest job. Click on the hyperlinks below to access the artifacts from the latest pipeline. 
| MISRA C Compliance Check | Model Compare Reports <br />(if any) | Model WebViews | Test & Coverage Results | Generated Code |
|--------------------------|--------------------------------|----------------|-------------------------|----------------|
| [Link](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/jobs/artifacts/main/browse/PA_Results/?job=Check_Modeling_Standards) | [Link](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/jobs/artifacts/main/browse/PA_Results/?job=Generate_Model_Comparison) | [Link](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/jobs/artifacts/main/browse/PA_Results/?job=Generate_Simulink_Web_View) | [Link](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/jobs/artifacts/main/browse/PA_Results/test_results/?job=Merge_Test_Results) | [Link](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/jobs/artifacts/main/browse/GeneratedArtifacts/CodeGen/?job=Zip_Up_Generated_Code_and_Details) |

You can then download the artifacts from the artifact webpage.
<br /><img src="Images/ArtifactLocation.png" width="500"/>
<br />

## CI/CD Pipelines: Current Status
| **[(InsideLabs) GitLab CI/CD](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode)** <br /><img src="Images/logo_GL.png" width="50"/>| **[GitHub Actions](https://github.com/smuckati1/EV_LaunchMode)** <br /><img src="Images/logo_GHA.png" width="50"/> | **[Azure DevOps](https://dev.azure.com/wyu0218/_git/EV_LaunchMode)** <br /><img src="Images/logo_ADO.svg" width="50"/>|
|:--------------------------------------------------:|:--------------------------------------------------:|:--------------------------------------------------:|
|Natick Hosted Windows Server <br /><img src="Images/logo_Windows.png" width="50"/>|Microsoft Hosted Linux VMs <br /><img src="Images/logo_VM.png" width="100"/>|Conatiner images hosted in Azure Registry <br /><img src="Images/ADO_Containers.png" width="120"/>|
|[![GLPipeline](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/badges/main/pipeline.svg)](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode/-/pipelines/) |[![GHAPipeline](https://github.com/smuckati1/EV_LaunchMode/actions/workflows/MBD_pipeline.yml/badge.svg?branch=main)](https://github.com/smuckati1/EV_LaunchMode/actions/)|[![ADOPipeline](https://dev.azure.com/wyu0218/EV_LaunchMode/_apis/build/status/EV_LaunchMode?branchName=refs/heads/main)](https://dev.azure.com/wyu0218/EV_LaunchMode/_build) |

The repository runs CI/CD pipelines across multiple platforms, showcasing seamless MATLAB and Simulink integration with diverse CI systems. Learn more [here](https://www.mathworks.com/help/matlab/matlab_prog/continuous-integration-with-matlab-on-ci-platforms.html).
> **<span style="color:red">[Note]</span>** Only clone the version from [InsideLabs](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode). See instructions [below](#special-instructions).

<br /><br />

## Why Continuous Integration?
- Frequent integration: Developers regularly merge code changes into a shared repository
- Automated testing: Each merge triggers an automated build and test process
- Early error detection: CI identifies issues early, keeping the codebase stable and release-ready
![Continuous Integration Workflow](Images/Workflow_with_CI.png)

When multiple engineers are involved in making algorthms, we need to ensure the changes being made are coordinated and thoroughly tested. Automating this work saves you a lot of time while preserving the quality of your code. 

## Demo Overview
In this example, we assume we are a team working to release a new "Launch Mode" for their electric cars. 
![Continuous Integration Workflow](Images/LaunchMode_UpdateBMS.png)
Update the Battery Management System (BMS) to increase the Max Discharge Current by 70%.

### What the MBD developer would do? 
![Continuous Integration - Developer Workflow](Images/CI_MBD_Developer_Actions.png)
### What the automated pipeline will execute?
![Continuous Integration - Automation Server Pipeline](Images/CI_MBD_CIPlatform_Actions.png)
--

## Key Features Showcased in this Demo
1. MATLAB Projects enable you to manage your environment and use source control
2. Process Advisor makes it easy to setup your CI pipeline, leveraging prebuilt tasks and a template process definition
3. Process Advisor enables you to auto generate YAML files for popular CI platforms (such as GitHub Actions), making it easy to adopt CI
4. The matlab-batch token enables you to license and execute multple jobs simulatenaously on different environemtns.
5. MATLAB, Simulink and Polyspace can be containerized and executed on the automation environment of your choice.

## Relevant Apps/Workflows
- Use Continuous Integration (CI) to automate checks, tests and codeGen
- Executing CI workflows with containerized MATLAB as your runner
- Use of the CI/CD support package for Simulink (i.e. Process Advisor)
- Using Projects and Source Control to manage your files/folders
- MISRA C Checks using Simulink Check
- MiL Testing with Simulink Test
- AUTOSAR - Generate Classic AUTOSAR compliant C code for BMS
- AUTOSAR - Generate Adaptive AUTOSAR compliant CPP code for VCU

## Special Instructions
- **[InsideLabs](https://insidelabs-git.mathworks.com/AE-Content/demos/ev_launchmode) is the single source of truth.**  
  Only clone, edit, and commit changes to the InsideLabs GitLab repository.
- **Push changes to InsideLabs GitLab only.**  
  Once changes are pushed, they are automatically propagated to the other repositories via GitLab repository mirroring.
  - <img src="Images/Mirrored_Repo.png" width="350"/>
- **All CI/CD pipelines will then run automatically.**  
  A single push to InsideLabs GitLab triggers:
  - the InsideLabs GitLab CI/CD pipeline
  - the mirrored GitHub Actions pipelines
  - the mirrored Azure DevOps pipelines

## Relevant Products
Simulink, Stateflow, System Composer, Simulink Test, Embedded Coder, AUTOSAR Blockset, Simulink Check

## Recording
[MATLAB EXPO 2025 - CI for Simulink](https://www.mathworks.com/videos/ci-for-simulink-speed-up-model-based-design-with-automated-pipelines-1762247698554.html)

## Contact
Sameer K Muckatira, Jason Ghidella, Winston Yu, Sagar Hukkire

## Relevant Industries
* MBD adopter who are looking to use Continuous Integration, and starting on DevOps
* Automotive customers doing AUTOSAR compliant code generation looking for MiL and SiL
