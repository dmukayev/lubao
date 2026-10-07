# Lubao — фирменный знак

Знак утверждён 2026-10-07: кремовая плитка `#FFF3DC`, оранжевый `#E8742E`, «LU» крупно, грузовик с «BAO» на борту.
Две правки относительно исходника: тонкая оранжевая обводка плитки (контраст на светлых обоях) и «BAO» крупнее (читаемость на 60 px).

| Файл | Для чего |
|---|---|
| `lubao-icon.svg` / `icon-1024.png` | иконка приложения iOS и Android (legacy), исходник для `flutter_launcher_icons` |
| `lubao-icon-foreground.svg` / `android-foreground-1024.png` | Android adaptive icon: foreground; background — цвет `#FFF3DC` |
| `lubao-mark.svg` / `mark-512.png` | знак без плитки: заставка, пустые состояния |
| `lubao-logo-horizontal.svg` / `logo-horizontal-900.png` | знак + «Lubao» для светлых шапок (экран входа, админка, письма) |
| `lubao-logo-horizontal-light.svg` / `logo-horizontal-light-900.png` | то же для тёмных фонов |
| `favicon-64/192/512.png` | веб: favicon и PWA-иконки |

Шрифт в SVG — Onest (вшит в приложение); при растеризации вне проекта подставить Onest, иначе «Lubao» уйдёт в Arial.
Цвета бренда: оранжевый `#E8742E`, крем `#FFF3DC`, тёмный `#1A1D26`. Основной синий интерфейса (`DESIGN.md`) не меняется — оранжевый только для знака, заставки и акцента «Lubao» в шапках.
