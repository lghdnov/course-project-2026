
#let arguments(..args, year: auto) = {
  let args = args.named()
  args.year = year
  return args
}

#let template(
  ministry: none,
  organization: (full: none, short: none),
  institute: (name: none),
  department: (name: none),
  report-type: "КУРСОВОЙ ПРОЕКТ",
  discipline: none,
  subject: none,
  student: (name: none, course: none, group: none, code: none, profile: none),
  manager: (name: none, degree: none, position: none),
  commission: (),
  city: none,
  year: auto,
) = {
  set text(size: 14pt)
  set par(justify: false, leading: 0.65em)

  // Ministry, university, institute, department header
  align(center)[
    #if ministry != none {
      upper(ministry)
      linebreak()
    }
    #if organization.full != none {
      upper(organization.full)
      linebreak()
    }
    #if institute.name != none {
      upper(institute.name)
      linebreak()
    }
    #if department.name != none {
      upper(department.name)
    }
  ]

  v(0.2cm)

  // Main title block
  align(center)[
    #text(weight: "bold", upper(report-type))
    #linebreak()
    по дисциплине
    #linebreak()
    #if discipline != none [
      «#discipline»
    ]
    #linebreak()
    на тему:
    #linebreak()
    #if subject != none [
      #text(weight: "bold")[«#subject»]
    ]
  ]

  v(0.2cm)

  // Student info (right-aligned)
  align(right)[
    #table(
      stroke: none,
      align: (left, left),
      inset: (x: 0pt, y: 1pt),
      columns: (auto, auto),
      [Выполнил: #h(0.3em)], [#student.name],
      [], [студент #student.course курса],
      [], [группы #student.group],
      [], [направления подготовки #student.code],
      [], [направленность (профиль)],
      [], [«#student.profile»],
      [], [очной формы обучения],
      [], [],
      [], [#box(width: 6cm, height: 1.2em, stroke: (bottom: 0.5pt))[]],
      [], [(подпись)],
    )
  ]

  v(0.2cm)

  // Manager info (right-aligned)
  align(right)[
    #table(
      stroke: none,
      align: (left, left),
      inset: (x: 0pt, y: 1pt),
      columns: (auto, auto),
      [Руководитель проекта: #h(0.3em)], [#(manager.name + if manager.degree != none and manager.degree != "" { ", " + manager.degree } else { "" } + ", " + manager.position)],
    )
  ]


  // Defense info
  table(
    stroke: none,
    align: (left, left, left, left),
    inset: (x: 0pt, y: 1pt),
    columns: (auto, 3.5cm, auto, 3.5cm),
    [Работа допущена к защите], [#box(width: 3.5cm, height: 1.2em, stroke: (bottom: 0.5pt))[]], [], [#box(width: 3.5cm, height: 1.2em, stroke: (bottom: 0.5pt))[]],
    [], [(подпись руководителя)], [], [(дата)],
    [], [], [], [],
    [Работа выполнена и защищена с оценкой], [#box(width: 3cm, height: 1.2em, stroke: (bottom: 0.5pt))[]], [Дата защиты], [#box(width: 3cm, height: 1.2em, stroke: (bottom: 0.5pt))[]],
    [], [(подпись)], [], [(дата)],
  )

  // Commission
  align(left)[Члены комиссии:]

  for member in commission {
    table(
      stroke: none,
      align: (left, left, left),
      inset: (x: 0pt, y: 1pt),
      columns: (9cm, 5cm, auto),
      [#member.position], [#member.name], [],
      [], [#box(width: 5cm, height: 1.2em, stroke: (bottom: 0.5pt))[]], [],
      [], [(подпись)], [],
    )
  }
}
