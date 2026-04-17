# Rastreamento Automático de Telas

Três abordagens disponíveis — escolha a que melhor se encaixa.

## Abordagem 1 — `SeniorScreenObserver` (StatefulWidget)

Mixin para `State<T>`. Dispara `logScreen` automaticamente no `initState`:

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SeniorScreenObserver<HomeScreen> {
  // screenName = 'HomeScreen' (automático via widget.runtimeType)

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('Home'));
  }
}
```

Para customizar o nome da tela:

```dart
@override
String get screenName => 'home_screen';
```

## Abordagem 2 — `SeniorNavigatorObserver` (global)

Captura **todas** as navegações do app automaticamente. Configuração única:

```dart
MaterialApp(
  navigatorObservers: [SeniorNavigatorObserver()],
);
```

Captura `push`, `pop` e `replace`, usando `route.settings.name` como `screenName`. Se a rota for anônima, usa `route.runtimeType.toString()` como fallback.

Ideal para apps com **rotas nomeadas**.

## Abordagem 3 — `SeniorStatelessScreenObserver` (StatelessWidget)

Mixin para `StatelessWidget`. O rastreamento ocorre via `addPostFrameCallback`, garantindo que o evento só é disparado **uma vez** após a renderização:

```dart
class ProfileScreen extends StatelessWidget
    with SeniorStatelessScreenObserver {

  @override
  Widget buildScreen(BuildContext context) {
    return Scaffold(body: Text('Profile'));
  }
}
```

> **Importante**: implemente `buildScreen()` ao invés de `build()`.

## Comparativo

| Mixin                           | Quando usar                                                       |
| ------------------------------- | ----------------------------------------------------------------- |
| `SeniorScreenObserver`          | Telas `StatefulWidget` — rastreamento no `initState`              |
| `SeniorNavigatorObserver`       | Apps com rotas nomeadas — configuração global única               |
| `SeniorStatelessScreenObserver` | Telas `StatelessWidget` — rastreamento via `addPostFrameCallback` |

---

Voltar: [Error Tracking](error-tracking.md)
