summary: Создание multiplatform модуля для нативных Android, iOS приложений
id: kmp-mobile-lesson-1
categories: multiplatform
environments: kotlin-mobile-mpp
status: published
Feedback Link: https://t.me/kotlinmppchats
Author: Aleksey Mikhailov <am@icerock.dev>

# Kotlin Mobile Multiplatform - Lesson 1
## Вводная
Duration: 5

В этом уроке мы сделаем из двух стандартных android и ios проектов мультиплатформенный проект с общей библиотекой на Kotlin Multiplatform. 

Для начала потребуются 2 проекта - Android и iOS созданные из шаблонов Android Studio и Xcode. Проекты нужно расположить в одну директорию, чтобы получилось так:
```bash
├── android-app
│   ├── build.gradle
│   ├── proguard-rules.pro
│   └── src
│       ├── androidTest
│       │   └── java
│       │       └── com
│       │           └── icerockdev
│       │               └── android_app
│       │                   └── ExampleInstrumentedTest.kt
│       ├── main
│       │   ├── AndroidManifest.xml
│       │   ├── java
│       │   │   └── com
│       │   │       └── icerockdev
│       │   │           └── android_app
│       │   │               └── MainActivity.kt
│       │   └── res
│       │       ├── drawable
│       │       │   └── ic_launcher_background.xml
│       │       ├── drawable-v24
│       │       │   └── ic_launcher_foreground.xml
│       │       ├── layout
│       │       │   └── activity_main.xml
│       │       ├── mipmap-anydpi-v26
│       │       │   ├── ic_launcher.xml
│       │       │   └── ic_launcher_round.xml
│       │       ├── mipmap-hdpi
│       │       │   ├── ic_launcher.png
│       │       │   └── ic_launcher_round.png
│       │       ├── mipmap-mdpi
│       │       │   ├── ic_launcher.png
│       │       │   └── ic_launcher_round.png
│       │       ├── mipmap-xhdpi
│       │       │   ├── ic_launcher.png
│       │       │   └── ic_launcher_round.png
│       │       ├── mipmap-xxhdpi
│       │       │   ├── ic_launcher.png
│       │       │   └── ic_launcher_round.png
│       │       ├── mipmap-xxxhdpi
│       │       │   ├── ic_launcher.png
│       │       │   └── ic_launcher_round.png
│       │       └── values
│       │           ├── colors.xml
│       │           ├── strings.xml
│       │           └── styles.xml
│       └── test
│           └── java
│               └── com
│                   └── icerockdev
│                       └── android_app
│                           └── ExampleUnitTest.kt
├── build.gradle
├── gradle
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradle.properties
├── gradlew
├── gradlew.bat
├── ios-app
│   ├── ios-app
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   │   ├── AppIcon.appiconset
│   │   │   │   └── Contents.json
│   │   │   └── Contents.json
│   │   ├── Base.lproj
│   │   │   ├── LaunchScreen.storyboard
│   │   │   └── Main.storyboard
│   │   ├── Info.plist
│   │   └── ViewController.swift
│   └── ios-app.xcodeproj
│       ├── project.pbxproj
│       └── project.xcworkspace
│           └── contents.xcworkspacedata
└── settings.gradle
```
Для этого создаем Android проект, после чего модуль `app` переименуем в `android-app` (не забывая изменить имя модуля в `settings.gradle`) и создаем iOS проект `ios-app` в корень android проекта.

Для удобства можно просто скачать начальное состояние [архивом](https://github.com/icerockdev/mobile-multiplatform-education/releases/tag/lesson-1-start).

## Создание модуля общей библиотеки
Duration: 30

Для добавления общей библиотеки нужно добавить новый gradle модуль (android и mpp библиотеки управляются системой сборки [gradle](https://gradle.org/)). Для создания модуля нужно:
Создаем директорию `mpp-library` (так будет называться наш gradle модуль) рядом с приложениями, чтобы получилось:
```bash
├── android-app
├── ios-app
└── mpp-library
```
Создаем `mpp-library/build.gradle` в нем будет располагаться конфигурация мультиплатформенного модуля. Содержимое файла для начала будет:
```groovy
apply plugin: 'com.android.library'
apply plugin: 'org.jetbrains.kotlin.multiplatform'
```
В `settings.gradle` добавляем подключение нового модуля:
```groovy
include ':mpp-library'
```
[step 1](https://github.com/icerockdev/mobile-multiplatform-education/commit/10b28e5f668f406ed4c4eb28f4240a14a01d8c58)

Добавляем в `mpp-library/build.gradle`:
```groovy
android {
    compileSdkVersion 28

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 28
    }
}
```
[step2](https://github.com/icerockdev/mobile-multiplatform-education/commit/b3ef95a5335548fb0b5d20f8a7f8bb6ac3bd4bb1)

Создаем `mpp-library/src/main/AndroidManifest.xml` с содержимым:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest package="com.icerockdev.library" /> 
```
[step3](https://github.com/icerockdev/mobile-multiplatform-education/commit/638b2cbc5cad2cfc10a53a72ec4b7d94c701aa15)

Добавляем в `mpp-library/build.gradle`:
```groovy
kotlin {
    targets {
        android()
        iosArm64()
        iosX64()
    }
}
```
[step4](https://github.com/icerockdev/mobile-multiplatform-education/commit/2cd19fe01677f4b47fadcab8e99a701643b13273)

Создаем директории:
- `mpp-library/src/commonMain/kotlin/`
- `mpp-library/src/androidMain/kotlin/`
- `mpp-library/src/iosMain/kotlin/`
[step5](https://github.com/icerockdev/mobile-multiplatform-education/commit/7ea6d9b919dacf64ef16ebbe4ac48c9f51da8b5a)

Переносим `AndroidManifest.xml` в `androidMain`:
`mpp-library/src/main/AndroidManifest.xml` → `mpp-library/src/androidMain/AndroidManifest.xml`
[step6](https://github.com/icerockdev/mobile-multiplatform-education/commit/67cf5b1a3743f1701f5a1c6577bacdb24d8f625b)

Добавляем в `mpp-library/build.gradle`:
```groovy
android {
    //...

    sourceSets {
        main {
            setRoot('src/androidMain')
        }
        release {
            setRoot('src/androidMainRelease')
        }
        debug {
            setRoot('src/androidMainDebug')
        }
        test {
            setRoot('src/androidUnitTest')
        }
        testRelease {
            setRoot('src/androidUnitTestRelease')
        }
        testDebug {
            setRoot('src/androidUnitTestDebug')
        }
    }
}
```
[step7](https://github.com/icerockdev/mobile-multiplatform-education/commit/24949ced80a8905e7bcfd2cee4c8b0617aaa519f)

Создаем `mpp-library/src/commonMain/kotlin/HelloWorld.kt`:
```kotlin
object HelloWorld {
    fun print() {
        println("hello common world")
    }
}
```
[step8](https://github.com/icerockdev/mobile-multiplatform-education/commit/9b174df4fb66d9448d5ebd29930c027ea7f29b09)

```groovy
android {
    // ...

    sourceSets {
        commonMain {
            dependencies {
                implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version"
            }
        }
    }
}
```
[step9](https://github.com/icerockdev/mobile-multiplatform-education/commit/748ed37ffe9b9f29ff992b609fe87f4b803ad746)

Добавляем в `android-app/build.gradle`:
```groovy
dependencies {
    // ...

    implementation project(":mpp-library")
}
```

Добавляем в `android-app/src/main/java/com/icerockdev/android_app/MainActivity.kt`:
```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {	
        // ...

        HelloWorld.print()
    }
}
```
[step10](https://github.com/icerockdev/mobile-multiplatform-education/commit/0d23cb4c657a097803f285bd4806df9247b0ab94)

Изменяем в `android-app/build.gradle` минимальную версию androidSdk для совместимости с `mpp-library`:
```groovy
android {
    // ...
    minSdkVersion 21
    // ...
}
```
[step11](https://github.com/icerockdev/mobile-multiplatform-education/commit/44813bfff5fb00badb0b77a1805e89fbcee6681c)

Создаем `mpp-library/src/androidMain/kotlin/AndroidHelloWorld.kt` с содержимым:
```kotlin
import android.util.Log

object AndroidHelloWorld {
    fun print() {
        Log.v("MPP", "hello android world")
    }
}
```

Добавляем в `android-app/src/main/java/com/icerockdev/android_app/MainActivity.kt`:
```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {	
        // ...

        AndroidHelloWorld.print()
    }
}
```
[step12](https://github.com/icerockdev/mobile-multiplatform-education/commit/5f52ed8e241d960bd27c70a7880ab9f544ececc1)

Создаем symlink'и `mpp-library/src/iosArm64Main` и `mpp-library/src/iosX64Main`, для этого делаем:
```bash
cd mpp-library/src
ln -s iosMain iosArm64Main
ln -s iosMain iosX64Main
```
[step13](https://github.com/icerockdev/mobile-multiplatform-education/commit/58f5caa489700bcf2a4bdbaab5723f420f00d275)

Создаем `mpp-library/src/iosMain/kotlin/IosHelloWorld.kt`:
```kotlin
import platform.Foundation.NSLog

object IosHelloWorld {
    fun print() {
        NSLog("hello ios world")
    }
}
```
[step14](https://github.com/icerockdev/mobile-multiplatform-education/commit/43504c8598d4ccbf9ddd530e818e8c2481167986)

Изменяем инициализацию iOS таргетов так, чтобы на выходе был скомпилирован objc framework для подключения к ios приложению.
```groovy
kotlin {
    targets {
        // ...

        def configure = {
            binaries {
                framework("MultiPlatformLibrary")
            }
        }

        iosArm64("iosArm64", configure)
        iosX64("iosX64", configure)
    }
}
```
[step15](https://github.com/icerockdev/mobile-multiplatform-education/commit/01406cfaf1ea087372cdafdcd29a73f5eff535df)

Подключаем к iOS приложению framework добавляя его в проект (add file to project).
скриншоты тут надо
[step16](https://github.com/icerockdev/mobile-multiplatform-education/commit/8b4f83e18537d429dd18b2e9421649e34b762d48)

```swift
import UIKit
import MultiPlatformLibrary

class ViewController: UIViewController {
  override func viewDidLoad() {
    // ...

    HelloWorld().print()
    IosHelloWorld().print()
  }
}
```
[step17](https://github.com/icerockdev/mobile-multiplatform-education/commit/a9ab47904c0c13e9602f4c9f74a391a5efb3d05b)

## Подключаем общую библиотеку через CocoaPods
Duration: 10

### Настраиваем компиляцию framework в единую директорию
В `mpp-library/build.gradle` добавляем:
В начале файла:
```groovy
import org.jetbrains.kotlin.gradle.plugin.mpp.Framework
import org.jetbrains.kotlin.gradle.tasks.KotlinNativeLink
```

В конце файла:
```groovy
tasks.toList().forEach { task ->
    if(!(task instanceof KotlinNativeLink)) return
    def framework = task.binary
    if(!(framework instanceof Framework)) return
    def linkTask = framework.linkTask

    def syncTaskName = linkTask.name.replaceFirst("link", "sync")
    def syncFramework = tasks.create(syncTaskName, Sync.class) {
        group = "cocoapods"

        from(framework.outputDirectory)
        into(file("build/cocoapods/framework"))
    }
    syncFramework.dependsOn(linkTask)
} 
```

### Настраиваем local CocoaPod содержащий наш Framework
Создаем `mpp-library/MultiPlatformLibrary.podspec`:
```ruby
Pod::Spec.new do |spec|
    spec.name                     = 'MultiPlatformLibrary'
    spec.version                  = '0.1.0'
    spec.homepage                 = 'Link to a Kotlin/Native module homepage'
    spec.source                   = { :git => "Not Published", :tag => "Cocoapods/#{spec.name}/#{spec.version}" }
    spec.authors                  = 'IceRock Development'
    spec.license                  = ''
    spec.summary                  = 'Shared code between iOS and Android'

    spec.vendored_frameworks      = "build/cocoapods/framework/#{spec.name}.framework"
    spec.libraries                = "c++"
    spec.module_name              = "#{spec.name}_umbrella"

    spec.pod_target_xcconfig = {
        'MPP_LIBRARY_NAME' => 'MultiPlatformLibrary',
        'GRADLE_TASK[sdk=iphonesimulator*][config=*ebug]' => 'syncMultiPlatformLibraryDebugFrameworkIosX64',
        'GRADLE_TASK[sdk=iphonesimulator*][config=*elease]' => 'syncMultiPlatformLibraryReleaseFrameworkIosX64',
        'GRADLE_TASK[sdk=iphoneos*][config=*ebug]' => 'syncMultiPlatformLibraryDebugFrameworkIosArm64',
        'GRADLE_TASK[sdk=iphoneos*][config=*elease]' => 'syncMultiPlatformLibraryReleaseFrameworkIosArm64'
    }

    spec.script_phases = [
        {
            :name => 'Compile Kotlin/Native',
            :execution_position => :before_compile,
            :shell_path => '/bin/sh',
            :script => <<-SCRIPT
MPP_PROJECT_ROOT="$SRCROOT/../../mpp-library"

"$MPP_PROJECT_ROOT/../gradlew" -p "$MPP_PROJECT_ROOT" "$GRADLE_TASK"
            SCRIPT
        }
    ]
end
```

### Подключаем наш local CocoaPod к проекту
Создаем `ios-app/Podfile`:
```ruby
# ignore all warnings from all pods
inhibit_all_warnings!

use_frameworks!
platform :ios, '11.0'

# workaround for https://github.com/CocoaPods/CocoaPods/issues/8073
# нужно чтобы кеш development pods корректно инвалидировался
install! 'cocoapods', :disable_input_output_paths => true

target 'ios-app' do
  # MultiPlatformLibrary
  # для корректной установки фреймворка нужно сначала скомпилировать котлин библиотеку
  pod 'MultiPlatformLibrary', :path => '../mpp-library'
end
```

В настройках проекта убираем ранее прописанную настройку `FRAMEWORK_SEARCH_PATHS` - скриншот.

Вызываем `pod install` в директории `ios-app` (заранее нужно установить [cocoapods](https://cocoapods.org)).

[step18](https://github.com/icerockdev/mobile-multiplatform-education/commit/1d6150d9b4ba98743fb0252ad9e40aee00141d1b)