# OSCA (V6Z80P+ v1.1, osca676p) → Karabas Go / Mini / Mini G: контекст проекта для Claude Code

Язык общения с пользователем: русский. Код, комментарии в RTL и README в репозитории: английский.

## Цель и статус
Портировать ядро OSCA (github.com/minexew/v6z80p, `OSCA/v6z80p_plus_v1.1`, проект `osca676p`, исходники в виде схем ISE) на платы
**Karabas Go**, **Karabas Mini** и **Karabas Mini G** (у всех Spartan-6 `xc6slx25-ftg256-2`, SDRAM MT48LC16M16A2 по тестам NanoMig, SRAM, MCU для SD/PS2).
**Статус (2026-11-11):** сборка ISE с T80pa (`src/karabas_<плата>.prj/.xst/.ucf/.ut`, `make` в `src/`, ветка `master`), один `v6z80p.kg`
на три платы (go, mini, minig в `core.json`), на всех трёх проверено на железе. Работает с FLOS 6.14 (образ по умолчанию),
клавиатура, тестовые образы, тест прерываний, демо parity (копроцессор ждёт SDRAM после переходов), звук MOD, джойстики, весь софт с образа SD из релиза v1.0 (программы minexew/v6z80p), OSD/сброс и виртуальная SD на образе
(OSD «SD card» = Image, `kg_sd_emu.v`, кеш секторов, burst MCU); все ограничения тайминга выполнены
(таблица map для каждой платы своя: `MAP_T_go = 2`, `MAP_T_mini = 2`, `MAP_T_minig = 5` в `Makefile`; запас однотактных путей `clk96` почти нулевой,
после правок RTL может понадобиться подобрать `-t` заново — см. `docs/OPEN_TASKS.md`).
Открытое — `docs/OPEN_TASKS.md`, раздел «Плата». Parity в симуляции: `sim/scripts/make_parity_image.py <v6z80p> <out.hex> --fast` + сборка с `IMG_BYTES=364544`.
Любые цифры задержек FPGA в `docs/SDRAM_TIMING.md` — мои оценки; результаты `trce` из ISE важнее их.

## Ветки и GitHub
Репозиторий: github.com/Caasper911/karabas-go-core-v6z80p (приватный, `origin`, ветка по умолчанию `master`).
- `master` — рабочая версия, проверенная на платах (T80pa, все такты из одного PLL, обёртка памяти и SDRAM с регистрами на границах доменов).
  2026-11-11 в неё влита `board/t80pa-pll` (fast-forward); до этого `master` была версией только для симуляции (`8345dff`).
- `board/t80pa-pll` удалена (2026-11-11, целиком в `master`).
- `wip/sdram-iob-timing` (только локально, на GitHub удалена) — правки для физического тайминга SDRAM (инвертированный `SDR_CLK`, регистры в IOB, захват данных в IOB-регистр,
  модель SDRAM с реальными задержками), ответвлена от старой `master`. **В ней известная регрессия**: звуковой DMA с копроцессором даёт несколько
  неверных чтений (см. `docs/OPEN_TASKS.md`). В `master` не вливать, пока `make regress` не пройдёт на этой ветке целиком.

## Структура
В корне только `modules/` (сабмодуль karabas-go-modules; обновление: `git -C modules pull`, затем коммит новой ссылки), `src/`, `CLAUDE.md` и `README.md`. В `src/`: `rtl/` (верхние модули плат `karabas_go_osca_top.v`, `karabas_mini_osca_top.v`, `karabas_minig_osca_top.v` в корне — только выводы,
видео/звук платы; общая часть (PLL, MCU, сброс, SoC, OSD, виртуальная SD) — `soc/kg_osca_system.v`, экземпляр `osca`, остальное по папкам: `soc/` (ядро OSCA `osca_core.v`, `kg_osca_soc.v`), `cpu/` (`kg_osca_cpu.v`, `t80pa/`, `t80/`), `memory/`, `video/`, `sound/`, `io/`, `debug/`, `prims/`; имена RTL-файлов в тексте без пути — из этого дерева), файлы сборки `karabas_{go,mini,minig}.prj/.xst/.ucf/.ut`, `core.json`, `Makefile` (ядро `v6z80p.kg`),
`docs/`, `scripts/make_test_cores.py` (.kg тестов), генераторы Verilog из схем, тестовые программы Z80 `tests/` (`video/`, `linecop/`, `sound/`, `system/`; из них собираются образы и для симуляции, и для `.kg1`), `roms/` (`.bin` для платы и генерации, `rom_tail.asm` — исходник подменённого boot ROM).
Всё для симуляции — в `src/sim/`: тестбенчи `tb_*`, модели (`kg_sysram_model.v`, `kg_tv80pa.v`, `kg_az80.v`, `tv80/`, `alt/`), эталон (`ref_overrides/`,
`golden/`), образы `roms/*.hex` (`lc_images/`, `modes/`), скрипты `scripts/` (`sim.sh`, `regress.py`, генераторы образов parity и MOD), сборки `build/`.
Все пути ниже — относительно `src/`; команды `make` запускать из `src/`.

## Как запускать (нужны: ISE 14.7, MSYS2 (make, bash, python3 + numpy + pillow), verilator ≥ 5 с `--binary --timing`, iverilog, sjasmplus;
## karabas-go-tools рядом с репозиторием: `C:\hobby\karabas-go-tools`)
Сборка как у ядер Andy Karpov (karabas-go-core-tsconf): всё из `src/`, команды `make` в оболочке MSYS2.
```
make                 # все платы: karabas_<плата>.prj/.xst/.ucf/.ut -> karabas_<плата>.bin -> v6z80p.kg (make_core.py по core.json)
make go|mini|minig   # одна плата
make <плата>-xst | -impl | -core | -report   # отдельные шаги; -report — ресурсы и итог тайминга
make tests           # .kg тестовых программ для платы: tests/out/<имя>.kg (scripts/make_test_cores.py)
make clean           # промежуточные файлы ISE
make unit            # контроллер SDRAM против модели SDRAM с проверкой таймингов (iverilog)
make sd-unit         # виртуальная SD (kg_sd_emu): команды, чтение, запись, кеш (iverilog)
make sim-build       # Verilator: sim/build/real/Vtb_boot;  make sim-ref — эталонная сборка (идеальные памяти)
make regress         # FLOS, спрайты, звук, копроцессор, 5 режимов, чтение VRAM процессором; сравнение с sim/golden/*.png
make regress-quick   # только режимы и чтение VRAM
```
Из PowerShell: `$env:MSYSTEM='UCRT64'; $env:CHERE_INVOKING='1'; & C:\msys64\usr\bin\bash.exe -l script.sh` (в Git Bash Verilator не находит
Perl-модули, а g++ пишет временные файлы в `C:\Windows`). ISE на Windows `make` вызывает с переменными `settings64.bat` (`XILINX`, `PATH`),
на Linux — через `source settings64.sh`. map иногда молча обрывается или падает на «Global Placement» (нет `karabas_<плата>_map.ncd`) — `make` ещё раз.
Модель шины T80pa в симуляции (`sim/kg_tv80pa.v`, сверена с GHDL):
`KG_EXTRA_DEFS="-DKG_CPU_T80PA -DKG_CPU_TV80PA" BUILD=sim/build/pa sim/scripts/sim.sh build real`. Verilog из `ghdl --synth` для T80 как модель НЕ годится.
`sim/scripts/sim.sh run <real|ref> <image.hex> <outdir> [ms]` запускает один образ; в `<outdir>` лягут `run.log` и `frame_N.ppm`.
Тестбенч `sim/tb_boot.sv` печатает проверки: `SDRAM model: ... violations`, `DMACHK` (байты, которые DMA звука получает из RAM, против ожидаемых),
`LCCHK` (байты списка копроцессора), `DMALAT`/`WAITCNT` (задержки и доля тактов с WAIT). Кадры пишутся на 290 и 950 мс (`frame_0`, `frame_1`).
Одноядерная машина считала ~100 мс симуляции в минуту с моделью SDRAM с задержками; на вашей машине это должно быть быстрее.

## Устройство (кратко; подробности — `docs/SIMULATION.md` (заметки разработки), описание проекта — `README.md`)
- Тактирование: один PLL (`kg_osca_system.v`, VCO 576 МГц): `clk96`, `clk16`, `clk32` (OSD, HDMI), `clk8` (FT_CLK_OUT на Mini/Mini G).
- Платы (верхние модули): Go — VGA (`V_CLK` ODDR2) и PCM5102; Mini — HDMI (zhdmi `hdmi_tx`, пиксельный такт `clk32`, ×5 из `kg_dcm`,
  DE = `rgb_oe` ядра через регистр `clk16` (`vid_de`), звук HDMI 48 кГц, DVI по `dvi_only` MCU) и сигма-дельта на AUDIO_L/R, FT812 только такт;
  Mini G — HDMI как Mini, PCM5102, `MCU_SCK` на тактовом выводе C9 через BUFG (burst MCU до 32 МГц, `MCU_BURST_MAX_MHZ`), burst на `MCU_IO[1:0]`.
  В UCF имена внутри общего модуля с префиксом `osca/`; сеть порта, используемого верхним модулем, получает имя верхнего (`clk16` на Go/Mini G, `osca/clk16` на Mini).
- Soft Z80: T80s (VHDL, `t80/`) на плате, tv80 (Verilog, `sim/tv80/`) только для симуляции (`-DKG_CPU_TV80`). `kg_osca_cpu.v`: арбитр шины
  (CPU/DMA ядра), выходы процессора проходят через регистры по спаду (настоящий Z80 меняет выходы после фронта, OSCA на это опирается).
- Видео-RAM и спрайт-RAM на одной SRAM через `kg_osca_mem.v` (v2): три доступа за такт 16 МГц (A tick1 чтение экрана, B tick3 спрайты,
  C tick5 запись/чтение второй фазы). Правки ядра (`patch_osca_top.py`): шина `vram_rdata2`, блиттер защёлкивает данные на спаде с
  регистровым CE, CPU читает видео через `vram_rdata2`, запись линейного буфера спрайтов задержана на такт (14 триггеров в `sprite_system513.v`).
- Системная RAM (512 КБ) на SDRAM: `kg_osca_sdram.v` (чтение спекулятивно по смене адреса слова, запись захватывается по стробу, регенерация
  не выполняется пока FPGA просит шину/владеет ею, два слота упреждающего чтения по `linecop_pc_o` для копроцессора, `WAIT_n` для CPU в `kg_osca_soc.v`).
- Загрузка без PIC/EEPROM: подменённый boot ROM (`roms/rom_tail.asm` → `roms/boot_rom_mcu.bin`), FLOS 5.68 кладёт в RAM по `$1000` MCU-загрузчик, пока ядро в сбросе; MCU держится в сбросе до `sd_init`.
- Периферия: PS/2-клавиатура из скан-кодов MCU (`kg_osca_ps2dev.v`), звук (`kg_osca_audio.v`), VGA или HDMI, OSD (`kg_osd_overlay` на `clk32`), сброс (OSD Reset / F12,
  кнопка платы, MCU BUSY). Джойстики: `JOY_L`/`JOY_R` MCU → `joy_bits` (порты 0/1 OSCA), на плате проверены. Не сделаны: PS/2-мышь, RTC, вторая SD, PIC/EEPROM (`sim/alt/kg_osca_eeprom.v` не симулировался).
- Виртуальная SD (`rtl/io/kg_sd_emu.v`, логика карты из `nextor_sd.v` karabas-go-core-msx): SPI-слейв на выводах SD ядра, секторы через `img_sdc`
  (file mounter MCU, слот 0, OSD «SD image»). Ncr = 2 (FLOS пропускает первый байт после команды); пока карта ждёт MCU (5–40 мс на сектор), CPU получает
  WAIT на `IN $0A` (FLOS ждёт токен данных всего 8000 опросов), но не при поднятом BUSRQ (иначе видеоядро не получает шину: мигание, зависания).
  Кеш 32 сектора (строка `lba[4:0]^lba[9:5]^lba[14:10]`, сквозная запись), burst MCU (Go: пины N9/M11, Mini/Mini G: `MCU_IO[1:0]`). Симуляция: `tb_boot +sdimg=<образ> +sddelay=<мс>`,
  образ — `sim/scripts/make_fat16_image.py`.
- Генерация Verilog из схем (`scripts/sch2v/`): `sch2v.py`, `gen_prims.py`, `patch_osca_top.py`, `trace_consumers.py` (нужен клон minexew/v6z80p, каталог схем
  `OSCA/v6z80p_plus_v1.1/osca676p`; проверенный вызов: `python3 scripts/sch2v/sch2v.py <каталог osca676p> <outdir> osca_pal`, затем `scripts/sch2v/patch_osca_top.py osca_pal.v osca_core.v`;
  `gen_prims.py [out.v]` пишет `kg_prims.v` (в `rtl/prims/kg_prims.v` есть ручные правки — сравнивать перед заменой),
  boot ROM подставляется переменной `OSCA_ROM_BIN=roms/boot_rom_mcu.bin`). Сгенерированные файлы лежат в репозитории, обычно регенерировать не нужно.

## Что проверено (симуляция) и как
Последний прогон `make regress` на старой `master` (`8345dff`, до слияния с `board/t80pa-pll`; на текущей не запускался): 11 из 11 тестов пройдено (flos, sprites, audio, lc_audio, lc_only, chunky_blit, planar4, tiles16, linedraw, sprites2, cpu_vram).
Эталон = то же ядро с идеальными асинхронными памятями (`sim/ref_overrides/`, `make ref`); кадры эталона — `sim/golden/*.png`.
- FLOS (баннер на 950 мс), спрайты (48 штук), копроцессор (список из 417 слов, 50 цветовых полос), 5 режимов (chunky+блиттер, планарный
  4 плоскости, тайлы 16×16, линейный рисовальщик, спрайты с отражением/высотами/движением), чтение VRAM процессором: кадры побитово совпадают.
- Звуковой DMA: ~18 тыс. чтений без ошибок; чтения списка копроцессора: 1626 без ошибок; CPU получает WAIT менее чем в 0,1% тактов.
- Допуски (нулевая задержка модели, развёртка `+dmady`/`+sysdy`): видеоядро ~2–3 такта 96 МГц; CPU без WAIT 9 тактов; звуковой DMA 11 тактов;
  копроцессор 6 тактов. Подробности в `docs/MEASUREMENTS.md`.
**Не проверено:** физический тайминг SDRAM и SRAM, сборка в ISE, работа на железе, режимы из списка в `docs/OPEN_TASKS.md`.

## Уроки (ошибки, которые уже были; не повторять)
1. Проверять данные там, где их забирает потребитель (копроцессор брал слово раньше конца доступа, проверка в конце доступа показала «верно»).
2. Эталон для блиттера должен иметь ОРИГИНАЛЬНЫЙ захват данных; с исправленным ядром и идеальной памятью блит ничего не копирует.
3. Задержки в моделях только транспортные (`reg <= #d`), инерционные `wire #d` срезают импульсы короче задержки.
4. Хэш выхода звука зависит от момента включения каналов (CPU с WAIT чуть медленнее): сравнивать байты DMA (`DMACHK`), а не хэш.
5. Целочисленное переполнение в счётчиках тестбенча (`WAITCNT`), `LDIR` портит `DE` в тестовых программах, `sed` по строкам стирал нужные строки RTL: после правки смотреть `grep`/diff.
6. Результат без сравнения с эталоном не называть «проверенным»; регрессию после каждой правки RTL.
7. «Тайминг выполнен» ничего не значит для путей между тактами, которые ISE считает несвязанными. Такт из счётчика через BUFG — отдельный домен
   с неизвестной фазой: все такты брать из одного PLL. Многотактные ограничения писать только из измеренных фаз (`KG_MEMLOG`, GHDL-модель T80pa).
8. Логика, которая смотрит на входы из другого домена каждый такт (детекторы смены, захват строба), в симуляции верна, а на плате ломается при длинном
   пути: решения принимать в фиксированные такты, где вход заведомо стабилен.
9. Меняя задержку для потребителя без WAIT (звуковой DMA берёт данные через 12 тактов), смотреть гистограмму задержек (`DMALATH`), а не только максимум.
10. Синтетические тесты DMA проверяли только последовательные чтения (их скрывает упреждающее чтение); parity ломался на переходах списка.
   Если программа на плате ведёт себя не так — запускать в симуляции её саму (`sim/scripts/make_parity_image.py` как образец), а не похожий тест.

## Справочные репозитории (клонировать рядом)
- `modules/` в корне репозитория (рядом с `src/`): https://github.com/andykarpov/karabas-go-modules (нужны 9 файлов, перечислены в `src/karabas_go.prj` как `../modules/...`; сабмодуль git)
- https://github.com/minexew/v6z80p (примеры `FLOS_based_programs/Simple_examples`, `tests/Misc`, `Bootcode`, `OSCA/ROM`; FLOS568F.OSF в `Contributions/Hans/CPM/v6z80pcpm30/`)
- https://github.com/andykarpov/karabas-go-core-nanomig (`fastram_sdram.v` — основа контроллера), `-core-next`, `-core-profi`: пины платы, Makefile и xst для ISE.
