# FocusDay

MVP iOS-приложения на SwiftUI: спокойный помощник, который помогает выбрать одно главное дело дня, вести короткий список задач и фиксировать вечерний итог.

## Структура

```text
FocusDay/
├── FocusDay.xcodeproj
├── FocusDay/
│   ├── App/
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   │   ├── Onboarding/
│   │   ├── Today/
│   │   ├── CreateTask/
│   │   ├── Progress/
│   │   ├── EveningSummary/
│   │   ├── Settings/
│   │   └── Components/
│   ├── Services/
│   ├── Shared/
│   ├── PreviewContent/
│   └── Resources/
└── FocusDayWidget/
```

SwiftData хранит задачи, состояние дня и вечерние итоги. WidgetKit получает название главной задачи через общий `FocusDayWidgetStore`. Заготовка `AIPlanningServiceProtocol` оставлена для будущего AI-помощника.
