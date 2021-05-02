summary: MOKO Widgets #7 - списки на виджетах
id: moko-widgets-7-ru
categories: lang-ru,moko,moko-widgets
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# MOKO Widgets #7 - lists on widgets
## Вводная
Duration: 5

Урок является продолжением [MOKO Widgets #6 - platform Screen](https://codelabs.kmp.icerock.dev/codelabs/moko-widgets-6/). Для выполнения данного урока нужно иметь проект, полученный в результате выполнения предыдущего урока.

Результатом прошлого урока было приложение с навигацией, стилизацией экранов, различными действиями на экранах, кастомными фабриками и платформенным экраном.

На этом уроке мы реализуем экран с списком элементов - это будет экран "друзья", на который можно попасть из профиля.

## Создание экрана со списком
Duration: 10

Добавим класс `FriendsScreen` основанный на `WidgetsScreen`:
`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/FriendsScreen.kt`:
```kotlin
class FriendsScreen(
    private val theme: Theme
) : WidgetScreen<Args.Empty>(), NavigationItem {

    override val navigationBar: NavigationBar = NavigationBar.Normal(title = "Friends".desc())

    override fun createContentWidget(): Widget<WidgetSize.Const<SizeSpec.AsParent, SizeSpec.AsParent>> {
        TODO()
    }
}
```

Контентом экрана будет `ListWidget`:
```kotlin
class FriendsScreen(
    ...
) : ... {
    ...

    override fun createContentWidget(): Widget<WidgetSize.Const<SizeSpec.AsParent, SizeSpec.AsParent>> {
        return with(theme) {
            list(
                size = WidgetSize.AsParent,
                id = Ids.List,
                items = TODO()
            )
        }
    }

    object Ids {
        object List : ListWidget.Id
    }
}
```

Positive
: Для создания виджета списка нам требуется передать Id - это нужно чтобы Android мог сохранить положение скролла и восстановить при перезаходе на экран или смене конфигурации.

Для хранения данных нам потребуется сущность `Friend`:
`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/Friend.kt`:
```kotlin
data class Friend(
    val id: Int,
    val name: String,
    val avatarUrl: String
)
```

Источником данных сделаем `FriendsViewModel`:
`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/FriendsViewModel.kt`:
```kotlin
class FriendsViewModel : ViewModel() {
    private val _friends: MutableLiveData<List<Friend>> =
        MutableLiveData(
            initialValue = List(10) {
                Friend(
                    id = it,
                    name = "friend $it",
                    avatarUrl = "https://exchange.icinga.com/jschanz/Batman%20Theme%20%28Light%29/logo"
                )
            }
        )
    val friends: LiveData<List<Friend>> = _friends
}
```

Сделаем получение данных на экране:
`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/FriendsScreen.kt`:
```kotlin
class FriendsScreen(
    ...
) : ... {
    ...

    override fun createContentWidget(): Widget<WidgetSize.Const<SizeSpec.AsParent, SizeSpec.AsParent>> {
        val viewModel = getViewModel { FriendsViewModel() }

        return with(theme) {
            list(
                size = WidgetSize.AsParent,
                id = Ids.List,
                items = viewModel.friends.map { friendsToTableUnits(it) }
            )
        }
    }

    private fun Theme.friendsToTableUnits(friends: List<Friend>): List<TableUnitItem> {
        return friends.map { friend ->
            TODO()
        }
    }

    ...
}
```

Остается настроить преобразование элемента данных `Friend` в элемент списка - `TableUnitItem`.

## Создание элемента списка
Duration: 10

`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/FriendUnitItem.kt`:
```kotlin
class FriendUnitItem(
    private val theme: Theme,
    itemId: Long,
    friend: Friend
) : WidgetsTableUnitItem<Friend>(
    itemId = itemId,
    data = friend
) {
    override val reuseId: String = "friendCell"

    override fun createWidget(data: LiveData<Friend>): UnitItemRoot {
        TODO()
    }
}
```

Мы унаследовались от `WidgetsTableUnitItem`, это специальный `TableUnitItem`, который умеет создавать элемент списка с контентом полученным из `Widget`. Для корректной работы на iOS требуется задать уникальный `reuseId` для данного класса элемента.

Positive
: В метод `createWidget` передается `LiveData<Friend>`, эта лайвдата будет автоматически изменяться при переиспользовании уже созданной view. 

Реализуем создание элемента:
```kotlin
class FriendUnitItem(
    ...
) : ... {
    ...

    override fun createWidget(data: LiveData<Friend>): UnitItemRoot {
        return with(theme) {
            constraint(
                size = WidgetSize.WidthAsParentHeightWrapContent
            ) {
                val title = +text(
                    size = WidgetSize.Const(
                        width = SizeSpec.MatchConstraint,
                        height = SizeSpec.WrapContent
                    ),
                    text = TODO(),
                )

                val avatar = +image(
                    size = WidgetSize.Const(
                        width = SizeSpec.Exact(64f),
                        height = SizeSpec.Exact(64f)
                    ),
                    image = TODO(),
                    scaleType = ImageWidget.ScaleType.FIT
                )

                constraints {
                    avatar.top pin root.top offset 16
                    avatar.left pin root.left offset 16
                    avatar.bottom pin root.bottom offset 16

                    title.left pin avatar.right offset 8
                    title.right pin root.right offset 16
                    title centerYToCenterY root
                }
            }
        }.let { UnitItemRoot.from(it) }
    }
}
```

Positive
: `UnitItemRoot` - специальный класс, ограничивающий допустимые для использования в элементе списка размеры.

```kotlin
inline class UnitItemRoot private constructor(private val wrapper: Wrapper) {

    companion object {
        fun from(widget: Widget<WidgetSize.Const<SizeSpec.AsParent, SizeSpec.Exact>>): UnitItemRoot {
            return UnitItemRoot(Wrapper(widget))
        }

        fun from(widget: Widget<WidgetSize.Const<SizeSpec.AsParent, SizeSpec.WrapContent>>): UnitItemRoot {
            return UnitItemRoot(Wrapper(widget))
        }

        fun from(widget: Widget<WidgetSize.AspectByWidth<SizeSpec.AsParent>>): UnitItemRoot {
            return UnitItemRoot(Wrapper(widget))
        }
    }

    val widget: Widget<out WidgetSize> get() = wrapper.widget
}
```
Исходный код класса показывает, что доступно всего 3 варианта размеров:
- ширина по родителю, высота фиксированная;
- ширина по родителю, высота по контенту;
- ширина по родителю, высота по соотношению сторон (относительно ширины).

За счет использования `inline` мы не накладываем дополнительную нагрузку на память - при компиляции класс будет стерт и использоваться будет `widget` напрямую.

### Привязка данных

Мы создали элемент списка с иконкой и текстом, но данные пока не привязаны. Как было сказано выше - данные должны считываться из специальной `LiveData`, которая передается в метод `createWidget`. Создание виджета будет производиться только при создании новых `View` для списка. В остальных случаях будет переиспользоваться уже существующая `View` и привязка данных будет происходить через обновление `LiveData`.

```kotlin
class FriendUnitItem(
    ...
) : ... {
    ...

    override fun createWidget(data: LiveData<Friend>): UnitItemRoot {
        return with(theme) {
            constraint(
                size = WidgetSize.WidthAsParentHeightWrapContent
            ) {
                val title = +text(
                    ...
                    text = data.map { it.name.desc() as StringDesc }
                )

                val avatar = +image(
                    ...
                    image = data.map { Image.network(it.avatarUrl) },
                    ...
                )

                ...
            }
        }.let { UnitItemRoot.Companion.from(it) }
    }
}
```

## Заполнение списка на экране
Duration: 5

`mpp-library/src/commonMain/kotlin/org/example/mpp/friends/FriendsScreen.kt`:
```kotlin
class FriendsScreen(
    ...
) : ... {
    ...

    private fun Theme.friendsToTableUnits(friends: List<Friend>): List<TableUnitItem> {
        return friends.map { friend ->
            FriendUnitItem(
                theme = theme,
                itemId = friend.id.toLong(),
                friend = friend
            )
        }
    }

    ...
}
```

Преобразуем список друзей в список юнитов, для отображения на UI.

## Тестирование
Duration: 10

Остается встроить экран в навигацию приложения.

Добавляем `NavigationItem` для экрана:
```kotlin
class FriendsScreen(
    ...
) : WidgetScreen<Args.Empty>(), NavigationItem {

    override val navigationBar: NavigationBar = NavigationBar.Normal(title = "Friends".desc())

    ...
}
```

Добавляем кнопку на экране профиля:
```kotlin
class ProfileScreen(
    ...
    private val routeFriends: Route<Unit>
) : ... {

    ...

    override fun createContentWidget() = with(theme) {
        constraint(size = WidgetSize.AsParent) {
            ...

            val friendsButton = +button(
                size = WidgetSize.WidthAsParentHeightWrapContent,
                content = ButtonWidget.Content.Text(Value.data("Friends".desc()))
            ) {
                routeFriends.route()
            }

            constraints {
                ...

                friendsButton topToBottom logoutButton
                friendsButton centerXToCenterX root
            }
        }
    }
}
```

Добавляем экран в фабрике профиля:
```kotlin
class ProfileFactory(
    ...
) {
    fun createProfileScreen(
        ...
        routeFriends: Route<Unit>
    ): ProfileScreen {
        return ProfileScreen(
            ...
            routeFriends = routeFriends
        )
    }

    ...

    fun createFriendsScreen(): FriendsScreen {
        return FriendsScreen(theme = theme)
    }
}
```

Добавляем его в приложении:
```kotlin
class App : BaseApplication() {
    ...

    private fun registerProfileTab(
        profileFactory: ProfileFactory,
        rootNavigationRouter: NavigationScreen.Router
    ): TypedScreenDesc<Args.Empty, ProfileNavigationScreen> {
        return registerScreen(ProfileNavigationScreen::class) {
            ...

            val friendsScreen = registerScreen(FriendsScreen::class) {
                profileFactory.createFriendsScreen()
            }

            val profileScreen = registerScreen(ProfileScreen::class) {
                profileFactory.createProfileScreen(
                    ...
                    routeFriends = navigationRouter.createPushRoute(friendsScreen)
                )
            }

            ...
        }
    }
}
```
