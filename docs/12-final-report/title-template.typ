// Custom title template for course project (курсовой проект)
// Compatible with modern-g7-32

#let arguments(..args, year: auto) = {
  let args = args.named()

  args.organization = if type(args.at("organization", default: none)) == dictionary {
    args.organization
  } else {
    (full: none, short: none)
  }

  args.institute = if type(args.at("institute", default: none)) == dictionary {
    args.institute
  } else {
    (name: none)
  }

  args.department = if type(args.at("department", default: none)) == dictionary {
    args.department
  } else {
    (name: none)
  }

  args.manager = if type(args.at("manager", default: none)) == dictionary {
    args.manager
  } else {
    (position: none, name: none, title: "Руководитель:")
  }

  args.student = if type(args.at("student", default: none)) == dictionary {
    args.student
  } else {
    (group: none, name: none)
  }

  args.year = year
  return args
}

#let template(
  ministry: none,
  organization: (full: none, short: none),
  institute: (name: none),
  department: (name: none),
  report-type: "ПОЯСНИТЕЛЬНАЯ ЗАПИСКА",
  about: "к курсовому проекту",
  subject: none,
  student: (group: none, name: none),
  manager: (position: none, name: none, title: "Руководитель:"),
  city: none,
  year: auto,
) = {
  set text(size: 14pt)
  set par(justify: false)

  // Ministry and university header
  align(center)[
    #if ministry != none [
      #ministry
      #v(0.3cm)
    ]
    #if organization.full != none [
      #upper(organization.full)
      #v(0.2cm)
    ]
    #if organization.short != none [
      #upper[(#organization.short)]
    ]
  ]

  v(1.2cm)

  // Institute and department
  align(center)[
    #if institute.name != none [
      #institute.name
      #v(0.2cm)
    ]
    #if department.name != none [
      #department.name
    ]
  ]

  v(2cm)

  // Main title block
  align(center)[
    #text(weight: "bold")[#upper(report-type)]
    #v(0.3cm)
    #if about != none [
      #upper(about)
      #v(0.5cm)
    ]
    #if subject != none [
      #text(weight: "bold")[
        #subject
      ]
    ]
  ]

  v(2cm)

  // Student and manager info table
  align(right)[
    #table(
      stroke: none,
      align: (left, left),
      inset: (x: 0pt, y: 4pt),
      columns: (auto, auto),
      [Выполнил:], [Иванов Дмитрий Романович],
      [], [3 курс, группа ПИЖ-б-о-23-2],
      [], [09.03.04 «Программная инженерия»],
      [], [очная форма обучения],
      [], [],
      [Проверил:], [#manager.position],
      [], [#manager.name],
    )
  ]

  v(1.5cm)

  align(left)[
    Отчёт защищён с оценкой #box(width: 3cm, height: 1em, stroke: (bottom: 0.5pt))[]
    #v(0.3cm)
    Дата защиты #box(width: 3cm, height: 1em, stroke: (bottom: 0.5pt))[]
  ]

  v(1fr)

  // City and year
  align(center)[
    #if city != none [
      #city
    ]
    #if year != auto and year != none [
      #year г.
    ]
  ]
}
