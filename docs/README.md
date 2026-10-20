# Документација — Е-продавница за технологија

Проект по предметот Напредни бази на податоци. PostgreSQL 18, DataGrip.

## Содржина

| Фаза | Документ | Статус |
| --- | --- | --- |
| 0 | [Опис на проектот](00_opis_proekt.md) | ажуриран, чека одобрение |
| 1 | [ЕР дијаграм](01_er_dijagram.md) | во тек |
| 2А | [DDL](02a_ddl.md) + [Речник на податоци](data_dictionary.md) | нацрт |
| 2Б | [Податоци и погледи](02b_podatoci_i_pogledi.md) | не е почната |
| 3 | [Оптимизација](03_optimizacija.md) | не е почната |
| 4 | [Функции, процедури, тригери](04_plpgsql.md) | не е почната |
| 5 | [Напредна тема](05_napredna_tema.md) | опционално |
| — | [Дневник на промени](CHANGELOG.md) | тековно |

## Тим и поделба

| Член | Модул |
| --- | --- |
| Член 1 — _име_ | Каталог и магацин |
| Член 2 — _име_ | Нарачки и плаќање |
| Член 3 — _име_ | Купувачи, постпродажба, администрација |

## Изградба на базата од нула

```bash
createdb -U postgres tech_shop
psql -U postgres -d tech_shop -v ON_ERROR_STOP=1 -f 00_ddl/ddl_v2.sql
# 01_data/*.sql по редослед, 02_views/*.sql, 03_optimization/indexes.sql, 04_plpgsql/*.sql
```

## Извоз за менторите

Документите се во Markdown. Еден документ во Word или PDF (со [pandoc](https://pandoc.org)):

```bash
cd docs
pandoc README.md 00_opis_proekt.md 01_er_dijagram.md 02a_ddl.md data_dictionary.md \
  -o ../dokumentacija.docx --toc
```
