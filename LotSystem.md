Лотовая система учёта финансов — выжимка
Базовая концепция
Лот — партия валюты/актива, купленная за определённую цену в определённый момент. Каждая покупка создаёт новый лот с фиксированным cost basis.
Каждая трата/конвертация (disposal) "съедает" лоты по выбранному алгоритму, фиксируя realized gain/loss = proceeds − cost basis.
Методы выбора лотов при disposal

FIFO — старые лоты первыми. Простой, дефолтный
HIFO — самые дорогие лоты первыми. Минимизирует gain
LIFO — свежие первыми
Spec ID — ручной выбор

Ключевой insight: если продаёшь ВСЁ что купил, total realized gain одинаков при любом методе. Метод влияет только на распределение gain между промежуточными событиями.
Базовая валюта (base currency)
Одна базовая валюта, выбранная раз и навсегда. Все cost basis выражены в ней. "Пара валют" не существует — только commodity → base.
Динамически менять base нельзя — это ломает математику. Зато можно делать display layer для показа отчётов в разных валютах поверх единого underlying accounting.
Архитектура: event sourcing
Raw transactions (immutable) = truth
+ Historical rates database
+ Configuration (base, method)
↓
Pure function reconstruct(...)
↓
Derived state: lots, realized gains, balances
Преимущества:

Single source of truth
Можно менять base/method retroactively → пересчёт
"What if" анализ
Чистый audit trail
Immutability raw data

Performance: materialized views или incremental computation для скорости.
Типы транзакций
ТипЧто происходитIncomeСоздаётся новый лот, cost basis = FMV в baseExpenseDisposal лотов по методу + расход в baseTransfer (same currency)Лот переезжает между счетами, cost basis сохраняется, no gainConversion (different currency)Disposal одной валюты + acquisition другой = два связанных события
FMV — центральная концепция
При conversion одна сумма в base currency используется одновременно как:

Proceeds для disposal
Cost basis для acquisition

pythonfmv = determine_fmv(tx, base, rates)
realized_gain = fmv − consumed_cost_basis  # для disposal
new_lot.cost_basis = fmv                    # для acquisition
Это обеспечивает internal consistency — wealth не появляется и не исчезает магически.
Как определять FMV
Варианты:

Если одна сторона = base — тривиально (просто amount)
Если обе стороны foreign — через rate одной из сторон (convention: through from side)
Implied rate (из actual amounts) vs mid-market rate (из rates table)

Главное — consistent выбор конвенции. Менять можно ретроактивно, но всю историю пересчитывать одинаково.
Спред / невыгодный курс
Когда покупаешь по spread (хуже mid-market), spread embedded в cost basis полученной валюты:
P2P: $1000 → 22.5M VND (worse rate)
FMV via USD = 90,000 RUB
VND lot cost = 90,000 RUB / 22.5M = 0.004 RUB/VND  ← выше mid-market 0.0036
При последующих тратах VND каждая транзакция реализует micro-loss — это и есть постепенная материализация spread. Total wealth change корректен, просто распределён во времени.
Не bug, а feature — позволяет видеть spread как отдельную метрику, а не плавающую в общем gain.
Income event
Получение валюты/токена извне:

Создаётся новый лот
Cost basis = FMV в base на момент получения
Записывается income event для отчётности

Granularity: per-event (точно, много лотов) vs aggregated (daily/monthly, проще). Architecture с event sourcing позволяет хранить per-event raw и derive aggregates при необходимости.
Chain conversions
RUB → USD → BTC → RUB = последовательность независимых disposal+acquisition событий. Каждое звено генерирует свой gain/loss. Total gain across chain ≈ economic result.
В DeFi цепочки могут быть длинными (свопы, LP, rewards), но та же логика применяется единообразно.
Реконструкция задним числом
Если есть полная история transactions + historical rates → можно построить лоты ретроактивно. Это и есть как работают Koinly, CoinTracker и подобные инструменты.
Качество результата зависит от:

Полноты данных (gaps = проблемы)
Точности rate database
Правильной классификации (transfer vs conversion)

Минимальная схема БД
sqltransactions (immutable raw data)
  - occurred_at, from_currency, from_amount, to_currency, to_amount
  - transaction_type, category, source

historical_rates (rate lookup)
  - rate_date, from_currency, to_currency, rate, source

accounts (metadata)
config (base_currency, lot_method)
Лоты и gains — derived, не stored persistently (или materialized views для performance).
Ключевые принципы

Лоты — derived from transactions, не наоборот
Cost basis = фактически заплачено (не "теоретическое")
Одна base currency (display может быть любая)
FMV — единое число для обеих сторон conversion
Consistency over correctness — выбрал конвенцию, применяй везде
Spread не исчезает — materializes где-то в системе
Total wealth change = sum всех events при любом методе

Это всё. Простая модель, мощная гибкость, чистая семантика.
