# Frontend Quality Suite

[English version](README.md)

Переносимый Agent Skill-плагин для production frontend-разработки и QA. Он включает оркестратор `frontend-production-qa` и два отдельных bundled specialist: `frontend-visual-qa` для визуального аудита и `frontend-accessibility-qa` для accessibility.

`frontend-accessibility-qa` также bundled и поддерживается в этом репозитории. Нормативная основа — W3C WCAG 2.2 Recommendation; APCA остаётся advisory и не становится конкурирующим compliance gate.

Он не заменяет специализированные навыки. Его задача — оркестрировать их, выбирать глубину проверки browser-facing изменений и определять, когда задача действительно подтверждена достаточными доказательствами.

**GitHub-репозиторий:** `SergejDAGDA/frontend-quality-suite-skill`. **ID установленного плагина:** `frontend-production-qa@codex-frontend-production-qa` (без изменений). **Bundled Skill ID:** `$frontend-production-qa`, `$frontend-visual-qa`, `$frontend-accessibility-qa`. ID Marketplace специально сохранён для совместимости с уже установленной нативной регистрацией Codex.

**Источник версии:** текущая версия plugin объявляется только в `plugin.json`. Переименование GitHub не обновляет локальный Marketplace checkout или кеш плагина. Если origin прежней установки содержит `codex-frontend-production-qa`, строгая проверка владения после смены ожидаемого URL может вернуть CONFLICT; её нельзя обходить или автоматически перерегистрировать. Изменения установки требуют отдельного разрешения и проверки. Поддержка других агентов не заявляется как протестированная.

## Зачем он нужен

Frontend может успешно собираться и при этом оставаться сломанным:

- исправление desktop ломает mobile;
- один screenshot выглядит правильно, а другой viewport переполнен;
- shared component ломается на другой странице;
- screenshots создаются, но не просматриваются;
- visual baseline обновляется вместо исправления regression;
- plugin выглядит установленным, хотя нужный skill payload фактически отсутствует.

`frontend-production-qa` добавляет вокруг этих случаев обязательный evidence-based workflow.

## Установка напрямую из GitHub

GitHub-репозиторий теперь является каноническим источником. При plugin-установке не нужно поддерживать отдельную ручную копию skill.

```powershell
codex plugin marketplace add SergejDAGDA/frontend-quality-suite-skill --ref main
codex plugin add frontend-production-qa@codex-frontend-production-qa
```

После установки запустите новую сессию Codex.

### Обновление из GitHub

```powershell
codex plugin marketplace upgrade codex-frontend-production-qa
codex plugin add frontend-production-qa@codex-frontend-production-qa
```

После этого также нужно открыть новую сессию Codex.

Вторая команда намеренно может выполняться повторно: она гарантирует материализацию plugin payload из обновлённого snapshot marketplace.

### Единственный источник версии

Публичная версия plugin хранится только здесь:

```text
plugin.json
```

В `SKILL.md` и dependency manifests отдельную release version больше добавлять не нужно.

Каждое опубликованное изменение plugin должно увеличивать version в manifest. Иначе новый Git snapshot может быть принят за уже закэшированный payload с той же версией.

### Переход со старой ручной установки

Если `frontend-production-qa` раньше копировался сюда:

```text
~/.agents/skills/frontend-production-qa/
```

перед plugin-установкой старую копию нужно удалить или переименовать. Codex не объединяет skills с одинаковым `name`, поэтому две копии могут одновременно появляться в selector.

## Встроенный Inspo MCP

Plugin включает hosted MCP проекта [Inspo](https://github.com/Nutlope/inspo):

```text
https://inspomcp.dev/api/mcp
```

Inspo даёт агенту поиск по реальным production-сайтам и их design patterns. Оркестратор использует его выборочно для:

- нового UI;
- новых компонентов;
- существенного redesign;
- поиска визуального направления;
- исследования hierarchy/layout;
- явного запроса на references или inspiration.

Inspo не становится источником дизайна существующего проекта. При bugfix, screenshot matching, responsive regression или необходимости сохранить уже утверждённый visual language главным источником остаётся сам проект.

Отдельная команда `codex mcp add inspo ...` при plugin-установке не нужна.

## Условный Motion specialist

Для задач с существенной анимацией оркестратор может использовать официальный внешний skill `motion` из [Motion AI Kit](https://github.com/motiondivision/ai-kit).

Он подключается условно для сложной анимации, enter/exit orchestration, layout motion, gestures, drag/reorder, scroll-linked effects, springs, работы с Motion API и диагностики animation performance.

Это **recommended**, но не required и не bundled dependency. Suite проверяет Motion только тогда, когда задача действительно его триггерит. Текущая устанавливаемая версия Motion определяется по npm dist-tag `latest`; версия Motion не закрепляется в нашем repository.

Если Motion отсутствует или его payload отличается от проверенного содержимого актуального npm-релиза, оркестратор предлагает точную provider-specific установку/обновление. Отличие от GitHub `main` само по себе не означает необходимость обновления. Изменение окружения всё равно требует явного разрешения пользователя.

Текущий provider installer вызывается так:

```powershell
npx motion-ai@latest
```

Installer может изменять skill files и hosted MCP configuration, поэтому действие остаётся явным и разрешённым пользователем.

Для простых hover/focus/press/fade/loading эффектов нужно предпочитать CSS, если его достаточно. Нельзя добавлять Motion runtime только из-за наличия agent skill. Нужно соблюдать reduced-motion/accessibility требования и проверять существенные animated states в реальном браузере.

## Условный Taste art-direction specialist

Когда frontend-задаче действительно нужна новая или заменяющая визуальная концепция, оркестратор может использовать внешний skill `design-taste-frontend` из [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill).

Он нужен для выразительных новых landing/marketing/public страниц, portfolio/showcase, осознанного redesign/restyle, явного запроса убрать generic/"AI-made" вид или создать новую визуальную систему app/dashboard по запросу пользователя.

Taste нужно пропускать для обычных bugfix, responsive regression, точного reference/screenshot matching, сохранения утверждённого design system, accessibility remediation, мелких визуальных правок и release QA без redesign.

На одну задачу выбирается **один art-direction authority**:

- существующий утверждённый дизайн проекта, если его нужно сохранить;
- Taste, если действительно разрешена новая/заменяющая концепция;
- design-direction возможности Impeccable только если Taste не выбран, а направление всё ещё нужно.

Если направление задал Taste, Impeccable может делать critique/polish внутри него, но не должен запускать конкурирующий redesign. Собственный inspector/look-fix loop Taste не заменяет viewport matrix, visual QA, accessibility QA, regression closure и completion evidence нашего suite.

Taste является **recommended**, но не required и не bundled. Suite проверяет его только при срабатывании Taste routing. Если skill отсутствует или author-owned plugin имеет более новую live-версию, оркестратор предлагает точную native Codex установку/обновление и применяет её только после явного разрешения.

## Bundled accessibility specialist

Suite включает собственный `frontend-accessibility-qa`, который является accessibility authority для browser-facing работы.

Когда accessibility conformance входит в scope, **WCAG 2.2 Level A/AA является hard gate**. APCA используется только как дополнительная perceptual design-подсказка и не может отменить WCAG failure.

Чтобы не запускать полный аудит после каждой мелкой правки, используются три режима:

- `DESIGN_GUARD` при выборе цветов, semantics, focus, target size и interaction;
- `AFFECTED_AUDIT` после обычных scoped изменений;
- `FULL_AUDIT` для существенного нового UI, явного WCAG-аудита, широких accessibility изменений или release acceptance с accessibility.

Accessibility specialist поддерживается внутри этого репозитория. Внешние WCAG/APCA agent skills используются только как reference sources и не являются runtime dependencies.

## Live specialist preflight

Внешний specialist не считается доступным только потому, что оркестратор на него ссылается.

После классификации задачи suite выводит точный набор required/triggered specialists и перед первым использованием выполняет **read-only live preflight**:

```powershell
.\scripts\preflight-frontend-specialists.ps1 -SkillId <exact-skill-id>
```

Registry `skills/frontend-production-qa/specialists.json` хранит только identity provider-а, repository, install channel и moving **current channel**. **Текущие номера версий внешних skills в нём намеренно не хранятся.**

Для npm-distributed providers вроде Impeccable и Motion authoritative current installable release определяется по настроенному npm dist-tag `latest`. Default branch репозитория автора остаётся источником provenance, документации и payload/reference checks, но его package version не обязана совпадать с npm `latest`.

Preflight различает, в частности, `INSTALLED_CURRENT`, `UPDATE_AVAILABLE`, `UPDATE_RECOMMENDED`, `MISSING`, `DISABLED`, `CONFLICT`, `PROVENANCE_UNKNOWN` и состояния с недостаточной remote/local evidence.

Если установка/обновление допустимы, оркестратор сначала показывает точное provider-native действие из `specialists.json` и ничего не меняет без явного разрешения.

Для Codex-plugin используется только exact author-owned marketplace/plugin identity после проверки ownership. Для provider CLI/installers используется текущая точная команда из registry, включая `@latest`, где это предусмотрено. Отдельного самописного package-manager wrapper нет, как и общего «update everything».

После mutation повторяется live preflight, при необходимости открывается свежая Codex session и разрешается exact Skill ID. Наличие package/skill на диске само по себе не доказывает активную загрузку.

## Основной workflow

```text
правила проекта
  -> классификация задачи + live specialist preflight
  -> анализ и воспроизведение
  -> optional design references, если действительно нужны
  -> conditional Taste art direction, если нужна
  -> accessibility design guard, если нужен
  -> frontend implementation
  -> conditional Motion specialist, если нужен
  -> design-quality слой, если нужен
  -> code checks
  -> реальный браузер
  -> responsive verification
  -> rendered visual QA
  -> accessibility closure
  -> regression closure
  -> условные review/security/performance/release gates
  -> доказательства завершения
```

## Классы проверки

| Класс | Типичное изменение | Проверка |
|---|---|---|
| A | layout, responsive, перенос текста, shared UI, navigation, подготовка релиза | реальный браузер + полная матрица 8 viewport + visual QA + regression closure |
| B | небольшая визуальная правка без реалистичного влияния на геометрию | реальный браузер + сокращённая матрица 3 viewport + visual inspection |
| C | невизуальное browser-facing изменение | точечная browser verification |
| D | backend/non-UI | frontend workflow не запускается, если rendered browser behavior не меняется |

Полная матрица:

```text
320x568
375x812
390x844
768x1024
1024x768
1280x800
1440x900
1920x1080
```

Сокращённая:

```text
390x844
768x1024
1440x900
```

Если меняется или подозревается breakpoint `B`, дополнительно проверяются `B-1`, `B`, `B+1`.

## Обязательный specialist stack

Workflow ожидает:

- `frontend-ui-engineering`
- `browser-testing-with-devtools`
- bundled `frontend-visual-qa`
- bundled `frontend-accessibility-qa`
- Chrome DevTools MCP

Первые два навыка берутся из [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).

`frontend-visual-qa` включён непосредственно в этот repository. Его исходный upstream — [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills), но используемой версией является поддерживаемая здесь Codex-адаптация.

Chrome DevTools MCP — из [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp).

Рекомендуемые условные specialists:

- [Taste Skill](https://github.com/Leonxlnx/taste-skill) / `design-taste-frontend` для новой или заменяющей art direction;
- [Impeccable](https://github.com/pbakaus/impeccable) для design-quality critique и polish внутри выбранного направления;
- [Motion AI Kit](https://github.com/motiondivision/ai-kit) для существенной animation/interaction работы.

Связанные необязательные skills:

- `ui-designer`
- `qa-expert`

Опционально можно использовать уже установленные:

- `karpathy-guidelines`
- `context-engineering`
- `maintain-project-memory`

Этот repository не устанавливает и не обновляет optional integrations.

## Подключение к проекту

Не копируйте весь skill в `AGENTS.md`.

Используйте короткий routing fragment:

```text
skills/frontend-production-qa/assets/AGENTS.frontend.fragment.md
```

Архитектура проекта, юридические ограничения, design decisions и project memory остаются главным источником правил.

## Обслуживание зависимостей

Сам plugin обновляется через Git-backed marketplace.

Скрипты внутри skill обслуживают только внешний specialist toolchain.

Bundled `frontend-visual-qa` обновляется вместе с самим frontend plugin. Скрипты не скачивают и не заменяют его из `daymade/claude-code-skills`.

```powershell
.\scripts\check-frontend-toolchain.ps1
.\scripts\plan-frontend-dependencies.ps1
.\scripts\bootstrap-frontend-toolchain.ps1
.\scripts\check-frontend-updates.ps1
.\scripts\update-frontend-toolchain.ps1 -Component agent-skills
```

Обычная frontend-задача не должна незаметно устанавливать или обновлять сторонние зависимости.

Планирование установки не изменяет окружение и указывает штатный путь `/plugins` только при подтверждённом отсутствии пакета и совпадении Git origin и каталога marketplace с ожидаемым репозиторием; установку проверяет и подтверждает сам пользователь. Старый комплексный bootstrap больше не устанавливает зависимости. Выбор компонента выполняется в режиме планирования без изменений. Прежний общий `-Apply` блокируется до проверки отката конкретного компонента и определения активной версии плагина. Перед установкой и обновлением читайте [регламент](skills/frontend-production-qa/references/toolchain-maintenance.md). Дублирующиеся ID навыков нужно разрешать по владельцу пакета; наличие файла в кэше не доказывает его загрузку в текущем Codex Desktop.

Подробности:

- [Зависимости](skills/frontend-production-qa/references/dependencies.md)
- [Матрица проверки](skills/frontend-production-qa/references/verification-matrix.md)
- [Обслуживание toolchain](skills/frontend-production-qa/references/toolchain-maintenance.md)

## Центральное правило regression closure

Любое последующее изменение CSS/layout/spacing/typography/positioning/sizing/visibility/breakpoint/shared styles делает предыдущую visual verification недействительной для затронутой области.

После исправления соответствующие browser и responsive проверки выполняются заново.

Нельзя сообщать `done`, `fixed` или `ready`, если обязательная проверка не завершена.

## Лицензия

MIT.
