summary: Создание приложения на базе moko-template
id: giphy-app-1
categories: multiplatform
environments: moko-template
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# GiphyApp #1 - Создание приложения на базе moko-template
## Вводная
Duration: 5

В этом руководстве будет описано создание небольшого приложения под Android и iOS с технологией [Kotlin Multiplatform](https://kotlinlang.org/docs/reference/multiplatform.html) основываясь на шаблоне [moko-template](https://github.com/icerockdev/moko-template). 

### Инструменты
Для работы потребуется:
- Android Studio 3.4.0+ (**не 3.5.1 так как там [баг, ломающий mpp](https://youtrack.jetbrains.com/issue/KT-34143)**);
- Xcode 10.3+;
- Xcode Command Line Tools (`xcode-select --install`);
- [CocoaPods](https://cocoapods.org/) (`sudo gem install cocoapods`);
- [JDK](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) - требуется для запуска `gradle` из `Xcode build phase`.

### Финальный результат
В результате будет получено приложение просмотра гифок с использованием [GIPHY API](https://developers.giphy.com/docs/api). Интерфейс приложения будет полностью нативный, проигрывание Gif будет сделано нативными библиотеками [glide](https://github.com/bumptech/glide) для Android и [SwiftyGif](https://github.com/kirualex/SwiftyGif) для iOS. 

|android app|ios app|
|---|---|
|![giphy-android-app](assets/giphy-android-app.webp)|![giphy-ios-app](assets/giphy-ios-app.webp)|

## Создание проекта из moko-template
Duration: 5

Для создания проекта будет использован шаблон [moko-template](https://github.com/icerockdev/moko-template). 

Positive
: Шаблон имеет настроенную конфигурацию сборки Android и iOS приложений с общей библиотекой, что позволяет не тратить время на интеграцию сборки общей библиотеки под iOS с iOS проектом, на конфигурирование Kotlin Multiplatform модулей и зависимостей (используя [mobile-multiplatform-gradle-plugin](https://github.com/icerockdev/mobile-multiplatform-gradle-plugin) конфигурация значительно упрощена). Так же шаблон имеет несколько фич-примеров.

### Use this template
Чтобы использовать шаблон нужно перейти на [GitHub репозиторий шаблона moko-template](https://github.com/icerockdev/moko-template) и нажать зеленую кнопку `Use this template`. Этим действием мы создадим новый репозиторий с контентом, соответствующим последнему коммиту из `master` ветки `moko-template`.

После успешного создания нового репозитория склонируем репозиторий себе - `git clone <git url of repo>`.

## Тестовая сборка
Duration: 5

Чтобы убедиться, что стартовое состояние корректно работает - запустим оба приложения. Для этого нужно:
- Android - открываем через Android Studio корневую директорию репозитория, после завершения `Gradle Sync` можно запустить модуль `android-app` как обычное приложение;
- iOS - устанавливаем CocoaPods проекта - в директории `ios-app` запускаем `pod install`, а после завершения открываем `ios-app/ios-app.xcworkspace` и жмем `Run` для запуска приложения.

Positive
: Время сборки Kotlin/Native части продолжительное (сборка запускается автоматически при `pod install` для корректной интеграции в проект, а так же при сборке iOS проекта).

## Настройки идентификации приложения
Duration: 10

Настройки индентификации приложения вносятся полностью так же, как и в обычных Android и iOS приложениях.

### Изменение Appliсation Id
Android - в файле `android-app/build.gradle.kts` изменить:
```kotlin
android {
    ...

    defaultConfig {
        ...
        
        applicationId = "dev.icerock.codelab.giphy"
        ...
    }
}
```
iOS - в Xcode в настройках проекта указать `Bundle Identifier` как на скриншоте:  
![Xcode bundle identifier](assets/giphy-1-1.png)

### Изменение имени приложения
Android - в файле `android-app/src/main/res/values/strings.xml` изменить:
```xml
<resources>
    <string name="app_name">Giphy App</string>
    ...
</resources>
```
iOS - в Xcode в настройках проекта указать `Display name` как на скриншоте:
![Xcode display name](assets/giphy-1-2.png)

### Изменение иконки
Ресурсы иконки можно скачать [по ссылке](assets/giphy-1-icons.zip).  
Для замены Android иконок нужно перенести содержимое из директории `android` архива в `android-app/src/main/res`. После этого нужно указать иконку в `android-app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application
        ...
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```
Для замены на iOS требуется заменить директорию `ios-app/src/Assets.xcassets/AppIcon.appiconset` на версию из архива.

### Изменение загрузочного экрана
Загрузочный экран есть на iOS и меняется он через Xcode в файле `ios-app/src/Resources/LaunchScreen.storyboard`. Для примера просто заменим текст, как на скриншоте:
![change launch screen](assets/giphy-1-3.png)

## Реализация загрузки списка Gif
Duration: 30

Перейдем к реализации логики самого приложения. Нужно чтобы приложение получало список Gif с сервиса GIPHY. В шаблоне сделан пример получения списка новостей с newsapi, реализовано это с использованием [moko-network](https://github.com/icerockdev/moko-network), который генерирует сетевые сущности и API классы из OpenAPI спецификации.

Имея OpenAPI спецификацию от GIPHY взятую с [apis.guru](https://apis.guru/browse-apis/) можно заменить получение новостей на получение Gif. 

### Замена OpenAPI спецификации
Заменим содержимое файла `mpp-library/domain/src/openapi.yml` содержимым из [OpenAPI спецификации сервиса GIPHY](assets/giphy-openapi.yml). После этого можно вызвать `Gradle Sync` и по завершению мы увидим что появились ошибки в коде, который работал с `newsapi`. Нужно обновить этот код под новую API.

Positive
: Сгенерированные файлы находятся по пути `mpp-library/domain/build/generate-resources/main/src/main/kotlin`

### Замена новостей на гифки в domain модуле
После замены OpenAPI спецификации в `domain` модуле требуется обновить следующие классы:
- `News` – он должен быть заменен на `Gif`;
- `NewsRepository` – поправить под `GifRepository`;
- `DomainFactory` – добавить `gifRepository` и предоставить ему нужные зависимости.

#### News -> Gif
`News` преобразуем в следующий класс:
```kotlin
@Parcelize
data class Gif(
    val id: Int,
    val previewUrl: String,
    val sourceUrl: String
) : Parcelable
```
Наша доменная сущность содержит `id` гифки, нужный для корректного определения элемента в списке и корректных анимаций на UI, а так же два варианта URL - полноразмерный вариант и превью.

К классу `Gif` добавим преобразование из сетевой сущности `dev.icerock.moko.network.generated.models.Gif` в доменную. Для этого добавим дополнительный конструктор:
```kotlin
@Parcelize
data class Gif(
    ...
) : Parcelable {

    internal constructor(entity: dev.icerock.moko.network.generated.models.Gif) : this(
        id = entity.url.hashCode(),
        previewUrl = requireNotNull(entity.images?.downsizedMedium?.url) { "api can't respond without preview image" },
        gifUrl = requireNotNull(entity.images?.original?.url) { "api can't respond without original image" }
    )
}
```
В конструкторе происходит маппинг полей из сетевой сущности в доменную, что позволяет уменьшить количество необходимых изменений при изменении API. Само приложение становится независимым от деталей реализации API.

#### NewsRepository -> GifRepository
`NewsRepository` превратим в `GifRepository` с следующим контентом:
```kotlin
class GifRepository internal constructor(
    private val gifsApi: GifsApi
) {
    suspend fun getGifList(query: String): List<Gif> {
        return gifsApi.searchGifs(
            q = query,
            limit = null,
            offset = null,
            rating = null,
            lang = null
        ).data?.map { Gif(entity = it) }.orEmpty()
    }
}
```
В данном репозитории нам достаточно получить `GifsApi` (генерируется `moko-network`) и вызвать метод API `searchGifs`, где на данный момент используем только поисковой запрос, остальные аргументы оставив по умолчанию.
Сетевые сущности сразу преобразуем в доменные, которые можем выдать наружу модуля (сетевые сущности генерируются с модификатором `internal`).

#### DomainFactory
В `DomainFactory` нужно заменить создание `newsApi` и `newsRepository`, заменим их на следующий код:
```kotlin
private val gifsApi: GifsApi by lazy {
    GifsApi(
        basePath = baseUrl,
        httpClient = httpClient,
        json = json
    )
}

val gifRepository: GifRepository by lazy {
    GifRepository(
        gifsApi = gifsApi
    )
}
```
`GifsApi` это сгенерированный класс, для создания требуется `baseUrl` (адрес сервера с которым работаем, передается он через фабрику с нативного уровня, для возможности конфигурирования разных окружений сборки на обеих платформах), `httpClient` (клиент для работы с сервером, от библиотеки [ktor-client](https://github.com/ktorio/ktor/)), `json` (сериализатор Json от библиотеки [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization)).  API доступно только внутри модуля, предоставляется как зависимость в репозитории.

`GifRepository` доступен вне модуля, для создания требуется только `gifsApi`.

Инициализация делается `lazy`, это означает что и API и репозиторий являются синглтонами (объекты живы пока жива фабрика, а ее держит `SharedFactory`, которая жива на все время жизни приложения).

### Обновление связи domain и feature:list в SharedFactory


## Смена стартового экрана
Duration: 5

В шаблоне по умолчанию приложение запускается с экрана настроек, а только после него делается переход на список. Для нашего приложения изменим стартовый экран сразу на список.

## Реализация поиска Gif
Duration: 15
