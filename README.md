
# Домашнее задание к занятию «12-06.md Репликация и масштабирование. Часть 1» - Теплов Михаил 

### Инструкция по выполнению домашнего задания

1. Сделайте fork [репозитория c шаблоном решения](https://github.com/netology-code/sys-pattern-homework) к себе в Github и переименуйте его по названию или номеру занятия, например, https://github.com/имя-вашего-репозитория/gitlab-hw или https://github.com/имя-вашего-репозитория/8-03-hw).
2. Выполните клонирование этого репозитория к себе на ПК с помощью команды `git clone`.
3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
   - впишите вверху название занятия и ваши фамилию и имя;
   - в каждом задании добавьте решение в требуемом виде: текст/код/скриншоты/ссылка;
   - для корректного добавления скриншотов воспользуйтесь инструкцией [«Как вставить скриншот в шаблон с решением»](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md);
   - при оформлении используйте возможности языка разметки md. Коротко об этом можно посмотреть в [инструкции по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md).
4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`).
5. Для проверки домашнего задания преподавателем в личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
6. Любые вопросы задавайте в чате учебной группы и/или в разделе «Вопросы по заданию» в личном кабинете.

Желаем успехов в выполнении домашнего задания.

---
### Задание 1

На лекции рассматривались режимы репликации master-slave, master-master, опишите их различия.

*Ответить в свободной форме.*

### Master–Slave

В схеме master–slave есть один главный сервер и один или несколько подчинённых.

Главный сервер (master) — это место, куда приложение записывает данные: добавляет, изменяет и удаляет записи.
Подчинённый сервер (slave) сам ничего не принимает на запись, он просто копирует все изменения с master и хранит у себя такую же копию данных.

Работает это так:
master фиксирует все изменения в специальных логах, а slave регулярно забирает эти изменения и повторяет их у себя. В итоге данные на slave всегда почти такие же, как на master.

Обычно slave используют для чтения — например, чтобы:
разгрузить основной сервер
делать отчёты
снимать резервные копии, не трогая master

Плюс такой схемы — она простая и надёжная.
Минус — если master упадёт, писать данные будет некуда, пока вручную не назначат новый master.

### Master–Master 

В схеме master–master оба сервера равноправные.
На любой из них можно писать данные, и каждый сервер передаёт свои изменения второму.

Фактически каждый сервер работает сразу в двух ролях:
 как master — принимает изменения
как slave — получает изменения от второго сервера

Это удобно, потому что:
если один сервер упал, второй продолжает работать
можно распределять нагрузку по записи

Но такая схема сложнее:
если одновременно изменить одни и те же данные на двух серверах, возможны конфликты
нужно специально настраивать автоинкремент, чтобы записи не пересекались
Поэтому master–master используют там, где важна отказоустойчивость или постоянная доступность сервиса, а не просто простота.

В заключении главная разница 
Master–Slave — один пишет, остальные копируют
Master–Slave проще и стабильнее
Master–Master — оба пишут и синхронизируются между собой
Master–Master сложнее, но даёт больше гибкости и отказоустойчивости


### Задание 2

Выполните конфигурацию master-slave репликации, примером можно пользоваться из лекции.

*Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.*

Скриншоты master:  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_master/1.png)
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_master/2.png)
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_master/3.png)

Конфигурационный файл master:  
[Master](https://github.com/mteplov/SQL1/blob/main/img/z2_master/mysqld.cnf)

Скриншоты slave:  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.1.png)  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.2.png)  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.3.png)  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.4.png)  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.5.png)  
![2 задание](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/2.6.png)  


Конфигурационный файл slave:  
[Slave](https://github.com/mteplov/SQL1/blob/main/img/z2_slave/mysqld.cnf)

---

## Дополнительные задания (со звёздочкой*)
Эти задания дополнительные, то есть не обязательные к выполнению, и никак не повлияют на получение вами зачёта по этому домашнему заданию. Вы можете их выполнить, если хотите глубже шире разобраться в материале.

---

### Задание 3* 

Выполните конфигурацию master-master репликации. Произведите проверку.

*Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.*

Скриншоты master1:  
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.1.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.2.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.3.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.4.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.5.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.6.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/3.7.png)

Конфигурационный файл master1:  
[Master1](https://github.com/mteplov/SQL1/blob/main/img/z3_master1/mysqld.cnf)

Скриншоты master2:  
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.1.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.2.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.3.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.4.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.5.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.6.png)
![3 задание](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/2.7.png)

Конфигурационный файл master2:  
[Master2](https://github.com/mteplov/SQL1/blob/main/img/z3_master2/mysqld.cnf)


