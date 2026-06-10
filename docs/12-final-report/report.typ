#import "@preview/modern-g7-32:0.2.0": abstract, gost, appendixes
#import "title-template.typ": template as course-project-template, arguments as course-project-args
#show: gost.with(
  title-template: course-project-template,
  city: "Ставрополь",
  year: 2026,
  hide-title: false,
  add-pagebreaks: true,
  ministry: "Министерство науки и высшего образования Российской Федерации",
  organization: (
    full: "ФГАОУ ВО «СЕВЕРО-КАВКАЗСКИЙ ФЕДЕРАЛЬНЫЙ УНИВЕРСИТЕТ»",
    short: "СКФУ",
  ),
  institute: (name: "Институт перспективной инженерии"),
  department: (name: "Межинститутская базовая кафедра"),
  report-type: "КУРСОВОЙ ПРОЕКТ",
  discipline: "Программная инженерия",
  subject: "Разработка кроссплатформенного клиентского приложения для сети Matrix",
  student: (
    name: "Иванов Дмитрий Романович",
    course: "3",
    group: "ПИЖ-б-о-23-2(1)",
    code: "09.03.04 «Программная инженерия»",
    profile: "Разработка и сопровождение программного обеспечения",
  ),
  manager: (
    name: "Свмойлов Ф.В.",
    degree: "",
    position: "доцент межинститутской базовой кафедры",
  ),
  commission: (
    (position: "доцент межинститутской базовой кафедры", name: "Свмойлов Ф.В."),
  ),
)
#show par: set par(spacing: 1.5em - 0.75em)

#abstract(
  "социальная сеть",
  "мессенджер",
  "протокол Matrix",
  "Java",
  "Spring Boot",
  "React",
  "REST API",
  "PCMEF",
)[
  В пояснительной записке описана разработка системы управления профилем пользователя и групповыми чатами для мессенджера на базе протокола Matrix.
  В аналитической части проведён анализ предметной области, бизнес-процессов, конкурентов и обоснована необходимость разработки.
  В проектной части представлены модель требований, модель предметной области, архитектурное проектирование на основе паттерна PCMEF с адаптацией под гексагональные принципы, проектирование базы данных и детальное проектирование с применением паттернов GoF.
  В реализационной части описана разработка бизнес-логики, пользовательского интерфейса на React, REST API с применением OpenAPI, системы безопасности и транзакций.
  В разделе тестирования приведены результаты модульного, интеграционного и системного тестирования.
  В разделе развёртывания описана контейнеризация с использованием Docker и деплой в Kubernetes через Helm.
  В разделе управления проектом представлены WBS, диаграмма Ганта, оценка трудозатрат по модели COCOMO и управление рисками.
]

#outline()

#include "00-introduction.typ"
#include "01-analytical.typ"
#include "02-project.typ"
#include "03-implementation.typ"
#include "04-testing.typ"
#include "05-deployment.typ"
#include "06-management.typ"
#include "07-conclusion.typ"

#bibliography("references.bib")

#show: appendixes

  = Листинги кода

Полные листинги исходного кода доступны в репозитории проекта:

- Бэкенд: `https://github.com/lghdnov/msocial`
- Frontend: `https://github.com/lghdnov/likma`
- SDK: `https://github.com/lghdnov/msocial-js-sdk`

