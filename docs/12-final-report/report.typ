#import "@local/modern-g7-32:0.2.0": abstract, gost, appendixes
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
    name: "Самойлов Ф.В.",
    degree: "",
    position: "доцент межинститутской базовой кафедры",
  ),
  commission: (
    (position: "доцент межинститутской базовой кафедры", name: "Самойлов Ф.В."),
    (position: "доцент межинститутской базовой кафедры", name: "Альбекова З.М."),
    (position: "заведующий межинститутской базовой кафедрой", name: "Новикова Е.Н."),
  ),
)


#pagebreak()
#set page(footer: context {
  let page-num = counter(page).get().first()
  if page-num == 1 {
    align(center)[Ставрополь 2026]
  } else {
    let intro-elems = query(<intro>)
    let intro-page = if intro-elems.len() > 0 {
      intro-elems.first().location().page()
    } else {
      11
    }
    
    if page-num < intro-page {
      none
    } else {
      align(center)[#page-num]
    }
  }
})

#include "assignment.typ"


#outline()

#include "08-abbreviations.typ"
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

#v(1cm)

  = DDL-скрипты базы данных


```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE
);

CREATE TABLE personal_infos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    birthday DATE,
    address VARCHAR(255),
    favorite_track_url VARCHAR(512),
    status VARCHAR(255),
    CONSTRAINT fk_personal_info_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE avatars (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    image_url VARCHAR(512) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_avatar_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_current_avatar ON avatars(user_id) WHERE is_current = TRUE;

CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE group_members (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    alias VARCHAR(100),
    display_name_override VARCHAR(100),
    CONSTRAINT fk_member_group FOREIGN KEY (group_id)
        REFERENCES communities(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_group_member UNIQUE(group_id, user_id)
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL,
    content TEXT,
    media_type VARCHAR(20) CHECK (media_type IN ('text', 'image', 'video', 'audio', 'link')),
    media_url VARCHAR(512),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_author FOREIGN KEY (author_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comment_post FOREIGN KEY (post_id)
        REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_author FOREIGN KEY (author_id)
        REFERENCES users(id) ON DELETE CASCADE
);
```

#v(1cm)

  = Скриншоты пользовательского интерфейса

#figure(image("images/08-ui/room_chat.png", width: 90%), caption: [Интерфейс комнаты чата]) <ui-room>

#figure(image("images/08-ui/user_profile.png", width: 90%), caption: [Профиль пользователя]) <ui-profile>

#figure(image("images/08-ui/user_profile_editor.png", width: 90%), caption: [Редактор профиля]) <ui-profile-editor>

#figure(image("images/08-ui/post_with_media.png", width: 90%), caption: [Публикация с изображением в ленте]) <ui-post>

#figure(image("images/08-ui/post_comments.png", width: 90%), caption: [Страница комментариев]) <ui-comments>

#figure(image("images/08-ui/msocial_settings.png", width: 90%), caption: [Настройки подключения к msocial API]) <ui-settings>

