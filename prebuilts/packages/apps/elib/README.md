## How to add elib to a prebuilt project

1. Add repository url in root of the project `build.gradle` or in `settings.gradle`. You can look where other repositories are added. Some common repositories are `google()`, `mavenCentral()`. You can add the below line

    - **For groovy**
        ```
        maven { url 'https://gitlab.e.foundation/api/v4/groups/9/-/packages/maven' }
        ```
    - **For kotlin**

        ```
        maven("https://gitlab.e.foundation/api/v4/groups/9/-/packages/maven")
        ```

2. Implement elib in the app module or in the module where you want to import elib. Can add this line 

    - **Groovy**
        ```
        implementation 'foundation.e:elib:0.0.1-alpha11'
        ```
    - **Kotlin**
        ```
        implementation("foundation.e:elib:0.0.1-alpha11")
        ```

Current version is `0.0.1-alpha11` if there is newer version available then that can be added.

An example of elib integration can be found [here](https://gitlab.e.foundation/e/os/camera/-/commit/2830edcb5b8a23e9524f9fc9d36ef1092008682a?merge_request_iid=47)

## How to add elib to a system project

There can be some cases where the app you want to add elib to is not a prebuilt project in those cases elib needs to be added to the makefile or blueprint of the project (Android.mk or Android.bp)

An example of it can be found [here](https://gitlab.e.foundation/e/os/android_packages_apps_Recorder/-/blob/v1-s/app/src/main/Android.bp?ref_type=heads#L35)
