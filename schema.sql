-- ======================================-- 5. Таблица для индивидуальных правил доступа пользователей (ОБЪЕДИНЕННАЯ)
-- Позволяет назначать или запрещать разрешения напрямую пользователю, в обход его роли.
-- Правило 'deny' имеет наивысший приоритет.
CREATE TABLE user_specific_rules (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    access_type ENUM('allow', 'deny') NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- 6. Таблица предметов=======
-- СОЗДАНИЕ СТРУКТУРЫ ТАБЛИЦ (DDL)
-- =================================================================

-- 1. Таблица ролей
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE -- Например, 'student', 'teacher', 'admin'
);

-- 2. Таблица разрешений
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- Например, 'view_grades', 'edit_schedule'
    description TEXT
);

-- 3. Таблица пользователей
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role_id INT NOT NULL,
    address VARCHAR(255) NULL,
    birth_date DATE NULL,
    phone_number VARCHAR(20) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);

-- 4. Таблица для связи ролей и разрешений
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- 5. Таблица для индивидуальных разрешений пользователей
CREATE TABLE user_permissions (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- 6. Таблица для индивидуальных ЗАПРЕТОВ разрешений пользователей (НОВАЯ)
-- Имеет приоритет над разрешениями роли.
CREATE TABLE user_permission_denials (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- 7. Таблица предметов
CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- 8. Таблица учебных годов
CREATE TABLE academic_years (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE, -- Например, "2024-2025"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE
);

-- 9. Таблица учебных периодов (четверти/семестры)
CREATE TABLE academic_terms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT NOT NULL,
    name VARCHAR(50) NOT NULL, -- Например, "1-я четверть"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE(academic_year_id, name)
);

-- 10. Таблица классов
CREATE TABLE classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    academic_year_id INT NOT NULL,
    teacher_id INT,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE(name, academic_year_id)
);

-- 11. Таблица зачислений
CREATE TABLE class_enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    class_id INT NOT NULL,
    academic_year_id INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE,
    UNIQUE(student_id, academic_year_id)
);

-- 12. Таблица расписания
CREATE TABLE schedule (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    subject_id INT NOT NULL,
    teacher_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number VARCHAR(20),
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(class_id, day_of_week, start_time),
    UNIQUE(teacher_id, day_of_week, start_time),
    UNIQUE(room_number, day_of_week, start_time)
);

-- 13. Таблица уроков
CREATE TABLE lessons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT NOT NULL,
    lesson_date DATE NOT NULL,
    topic VARCHAR(255),
    notes TEXT,
    FOREIGN KEY (schedule_id) REFERENCES schedule(id) ON DELETE CASCADE,
    UNIQUE(schedule_id, lesson_date)
);

-- 14. Таблица оценок
CREATE TABLE grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    lesson_id INT NOT NULL,
    teacher_id INT NOT NULL,
    academic_term_id INT NOT NULL,
    grade INT NOT NULL CHECK (grade >= 1 AND grade <= 10),
    grade_type ENUM('classwork', 'homework', 'test', 'exam', 'quiz') NOT NULL,
    date_assigned DATE NOT NULL,
    notes TEXT,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_term_id) REFERENCES academic_terms(id) ON DELETE CASCADE
);

-- 15. Таблица посещаемости
CREATE TABLE attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    lesson_id INT NOT NULL,
    status ENUM('present', 'absent', 'late', 'excused') NOT NULL,
    notes TEXT,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    UNIQUE(student_id, lesson_id)
);

-- 16. Таблица домашних заданий
CREATE TABLE homework (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lesson_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
);

-- 17. Таблица для исходящих СМС-рассылок
CREATE TABLE sms_dispatches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    message_text TEXT NOT NULL,
    recipient_data JSON,
    status ENUM('pending', 'sent', 'failed') NOT NULL DEFAULT 'pending',
    source_trigger VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP NULL,
    error_message VARCHAR(255)
);

-- 18. Таблица ежедневных пропусков
CREATE TABLE daily_absences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    absence_date DATE NOT NULL,
    reason VARCHAR(255),
    approved_by_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(student_id, absence_date)
);

-- 19. Таблица итоговых оценок
CREATE TABLE final_grades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_id INT NOT NULL,
    academic_term_id INT NOT NULL,
    grade INT NOT NULL,
    notes TEXT,
    assigned_by_teacher_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (academic_term_id) REFERENCES academic_terms(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by_teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(student_id, subject_id, academic_term_id)
);


-- =================================================================
-- ЗАПОЛНЕНИЕ ДАННЫМИ (DML - SEED DATA)
-- =================================================================

-- Вставка базовых ролей
INSERT INTO roles (name) VALUES ('student'), ('teacher'), ('admin');

-- Вставка базовых разрешений
INSERT INTO permissions (name, description) VALUES
-- Студент
('view_own_profile', 'Просмотр собственного профиля'),
('view_own_grades', 'Просмотр собственных оценок'),
('view_own_attendance', 'Просмотр собственной посещаемости'),
('view_own_homework', 'Просмотр собственных домашних заданий'),
('view_class_schedule', 'Просмотр расписания своего класса'),

-- Учитель
('view_teacher_profile', 'Просмотр собственного профиля учителя'),
('manage_lessons', 'Управление уроками (создание, редактирование тем) для своих классов'),
('manage_grades', 'Управление оценками (выставление, редактирование) для своих классов'),
('manage_attendance', 'Управление посещаемостью (отметка присутствующих) для своих классов'),
('manage_homework', 'Управление домашними заданиями (создание, редактирование) для своих классов'),
('view_student_list_for_class', 'Просмотр списка учеников в своих классах'),

-- Администратор
('manage_users', 'Управление всеми пользователями (создание, редактирование, удаление)'),
('manage_roles', 'Управление ролями и разрешениями'),
('manage_classes', 'Управление классами (создание, назначение классных руководителей)'),
('manage_subjects', 'Управление предметами'),
('manage_academic_year', 'Управление учебными годами и периодами'),
('manage_enrollments', 'Управление зачислением учеников в классы'),
('view_all_data', 'Просмотр любых данных в системе (оценки, посещаемость и т.д.)'),
('generate_reports', 'Генерация отчетов по успеваемости и посещаемости'),
('send_sms_notifications', 'Отправка СМС-уведомлений');

-- Назначение разрешений ролям
-- Получаем ID ролей
SET @student_role_id = (SELECT id FROM roles WHERE name = 'student');
SET @teacher_role_id = (SELECT id FROM roles WHERE name = 'teacher');
SET @admin_role_id = (SELECT id FROM roles WHERE name = 'admin');

-- Разрешения для студента
INSERT INTO role_permissions (role_id, permission_id)
SELECT @student_role_id, id FROM permissions WHERE name IN (
    'view_own_profile',
    'view_own_grades',
    'view_own_attendance',
    'view_own_homework',
    'view_class_schedule'
);

-- Разрешения для учителя
INSERT INTO role_permissions (role_id, permission_id)
SELECT @teacher_role_id, id FROM permissions WHERE name IN (
    'view_teacher_profile',
    'manage_lessons',
    'manage_grades',
    'manage_attendance',
    'manage_homework',
    'view_student_list_for_class',
    'view_class_schedule'
);

-- Разрешения для администратора (все права)
INSERT INTO role_permissions (role_id, permission_id)
SELECT @admin_role_id, id FROM permissions;