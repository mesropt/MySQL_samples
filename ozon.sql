-- Общее текстовое описание БД и решаемых ею задач
/*Это база данных интернет-магазина ozon.ru. 
 * 
 * База данных хранит сведения обо всех пользователях, их покупках, банковских картах, пунктах выдачи товаров, 
 * список товаров с их характеристиками, каталоги, куда входят товары.
 * 
 * База данных позволяет не только хранить, но и анализировать покупательские предпочтения пользователей 
 * с помощью сортировки купленных товаров по разделам. В сегменте детских товаров магазин 
 * реализует товары в не более среднего ценового диапазона, в связи с чем менеджер магазина
 * не сможет установить цену на товар из данной категории более 30000 рублей, так как в базе данных работает
 * триггер, не дающий это сделать. */

DROP DATABASE IF EXISTS ozon;
CREATE DATABASE ozon;
USE ozon;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY,
    firstname VARCHAR(100) COMMENT 'Имя',
    lastname VARCHAR(100) COMMENT 'Фамилия',
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(100),
    phone BIGINT UNIQUE,
    home_adress VARCHAR(200),
    gender VARCHAR(6),
    birthday_at DATE,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	is_deleted bit default 0,
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT = 'Пользователи';

DROP TABLE IF EXISTS bank_cards;
CREATE TABLE bank_cards (
	user_id SERIAL PRIMARY KEY,
	bank_card_number CHAR (16) UNIQUE,
	emitter VARCHAR(50),
	payment_system VARCHAR(50),
	beginning_date DATE,
	expiration_date DATE,
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Банковские карты';

DROP TABLE IF EXISTS catalogs;
CREATE TABLE catalogs (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название раздела',
	UNIQUE unique_name(name(40))
) COMMENT = 'Разделы интернет-магазина';

DROP TABLE IF EXISTS products;
CREATE TABLE products (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название',
	description TEXT COMMENT 'Описание',
	price DECIMAL (11,2) COMMENT 'Цена',
	catalog_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY index_of_catalog_id (catalog_id)
) COMMENT = 'Товарные позиции';

DROP TABLE IF EXISTS waiting_list;
CREATE TABLE waiting_list(
	user_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Список ожидания';

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY index_of_user_id(user_id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Заказы';

DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
	id SERIAL PRIMARY KEY,
	reviewing_user_id BIGINT UNSIGNED NOT NULL,
	for_product_id BIGINT UNSIGNED NOT NULL,
	body TEXT,
	created_at DATETIME DEFAULT NOW(),
	FOREIGN KEY (reviewing_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (for_product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Отзывы о товарах';

DROP TABLE IF EXISTS pickup_points;
CREATE TABLE pickup_points (
	id SERIAL PRIMARY KEY,
    phone BIGINT UNSIGNED NOT NULL,
    adress VARCHAR(200),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Пункты выдачи';

DROP TABLE IF EXISTS purchases;
CREATE TABLE purchases(
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	pickup_point_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	INDEX purchases_id_idx(id),
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (pickup_point_id) REFERENCES pickup_points(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Покупки';

DROP TABLE IF EXISTS users_purchases;
CREATE TABLE users_purchases(
    user_id BIGINT UNSIGNED NOT NULL,
	purchase_id BIGINT UNSIGNED NOT NULL,
	value INT UNSIGNED COMMENT 'Запас товарной позиции на складе',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (user_id, purchase_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Заказы';

DROP TABLE IF EXISTS storehouses;
CREATE TABLE storehouses (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) COMMENT 'Название',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Склады';

DROP TABLE IF EXISTS storehouses_products;
CREATE TABLE storehouses_products (
	storehouse_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	value INT UNSIGNED COMMENT 'Запас товарной позиции на складе',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (storehouse_id, product_id),
	FOREIGN KEY (storehouse_id) REFERENCES storehouses(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Запасы на складе';

DROP TABLE IF EXISTS orders_products;
CREATE TABLE orders_products (
	id SERIAL PRIMARY KEY,
	order_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	total INT UNSIGNED DEFAULT 1 COMMENT 'Количество заказанных товарных позиций',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	FOREIGN KEY (order_id) REFERENCES orders(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(catalog_id) ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT = 'Состав заказа';

-- Скрипты наполнения БД данными
INSERT INTO catalogs 
(id, name)
VALUES
	(1, 'Электроника'),
	(2, 'Одежда'),
	(3, 'Обувь'),
	(4, 'Дом и сад'),
	(5, 'Детские товары'),
	(6, 'Красота и здоровье'),
	(7, 'Бытовая техника'),
	(8, 'Спорт и отдых'),
	(9, 'Строительство и ремонт'),
	(10, 'Аптека'),
	(11, 'Товары для животных'),
	(12, 'Книги'),
	(13, 'Туризм, рыбалка, охота'),
	(14, 'Автотовары'),
	(15, 'Мебель'),
	(16, 'Хобби и творчество'),
	(17, 'Ювелирные украшения'),
	(18, 'Аксессуары'),
	(19, 'Всё для игр'),
	(20, 'Канцелярские товары');

INSERT INTO users (firstname, lastname, email, password_hash, phone, home_adress, gender, birthday_at, created_at, updated_at) VALUES ('Thea','Mayer','iherzog@example.com','e4dc06dfc3eb2dfcdc07e84e07cab8934d3c7937',9774527194,'949 Pasquale Flat Apt. 957\nEast Patricia, ND 96952','female','1994-12-23','1990-06-12 00:41:14','2000-02-21 14:21:51'),('Adolphus','DuBuque','sammie.cremin@example.org','61f65e534c648d66c588aada275827caa935aa5b',9100704487,'561 Cathryn Vista Suite 202\nWest Julius, VA 80356-5239','male','2009-02-22','2002-11-20 09:42:21','2011-01-11 00:28:30'),('Damien','Bahringer','winston.boehm@example.com','55719ee905617cd0e3d5fc3eabcd00c7e6d10dd0',9720166224,'618 Prosacco Turnpike Suite 045\nNaderchester, AZ 24990-4196','female','1997-12-25','2010-06-14 18:43:39','1978-03-11 10:30:53'),('Modesta','Larkin','ardith.ruecker@example.net','d2b83fa64e3738fd755ae2c344f0339b6600e45e',9786286811,'204 Marlene Lock\nNew Oda, CO 65831-4995','male','1983-01-17','2014-09-27 15:54:12','1982-11-14 22:25:56'),('Enoch','Prohaska','hermiston.hazel@example.org','d2c652199ab4b47c76e1362c27fa47543351aa2c',9410840253,'618 Gonzalo Trail Suite 359\nJoanport, CA 65220','male','2011-04-28','2009-02-08 02:04:42','1979-03-06 14:26:05'),('Eulalia','Botsford','rod.crona@example.net','257ab4f32801bb8ef5d947cbc783e0d776dd2b7a',9296748557,'0323 Fisher Wall\nMayerland, MS 20319-2712','female','1999-07-24','1978-06-29 17:04:09','2009-08-16 07:31:12'),('Rylan','Sipes','mclaughlin.finn@example.org','4ae15be877e681ecd09d7159aa0ed02e6dae709f',9680176090,'90764 Aimee Plaza\nMetzmouth, DC 06650-6374','male','1984-10-21','1981-06-28 16:23:55','2003-03-15 10:06:54'),('Gideon','Bashirian','bleuschke@example.com','fe0a322e1bb4430ea669d101eb471dee7f60da28',9999143105,'43385 Nikko Trail\nNorth Brendenview, IL 94274-0319','female','1991-12-12','2000-10-13 19:11:38','1981-12-24 13:46:55'),('Daniella','Little','fgutkowski@example.net','7708d1a85d884776b4cee2fcb7229d382e582426',9519831717,'1092 Jaunita Path Suite 251\nWest Nicolasville, KS 69376','male','2015-09-10','2018-07-19 23:17:32','1987-02-18 08:10:47'),('Jerald','Lakin','bauch.elliot@example.net','a7406d7b5934fc5ba85f7a9d3845ab5dfd5dad51',9088482744,'2811 Hilma Mount\nLake Candida, MS 44757','female','2001-10-29','1988-03-12 18:49:31','1992-07-10 09:40:59'),('Kobe','Prosacco','lucas54@example.com','b4accabfad2e11778d17563280b9a3bed2226c66',9134805819,'7467 Leuschke Dam\nColleenville, AK 87979-2168','female','2009-03-02','1987-11-29 20:05:03','2016-09-18 06:10:46'),('Gladys','Connelly','gabernathy@example.org','f7ff4e7ee65e4bd0a3bec8f73c79fd24365b577a',9010120994,'92399 Volkman Plaza Apt. 365\nPort Helmer, DE 29785','male','1988-08-06','2013-10-09 18:42:18','2017-12-17 11:31:34'),('Fletcher','Von','thodkiewicz@example.net','e1fa2d4a77917d059871791174fc85fc8ca70b15',9183189255,'5260 Linnie Mountain\nPort Monicaland, SC 69366','female','2003-04-20','1981-12-18 01:40:29','1971-02-15 05:06:11'),('Louisa','Veum','borer.giovani@example.net','b1718aa8493ed3d15dd3f91787b9275b29f28d22',9033153216,'3556 Johan Locks Suite 473\nGleasonport, MO 35165','female','1974-11-02','1976-12-06 04:03:48','1983-07-15 13:01:08'),('Consuelo','Howe','mosciski.jaquan@example.net','6876c51cacae9ed90ea3648b0e981c67115c6d07',9940869049,'756 Stehr Corner Apt. 051\nPort Albinatown, GA 09983-6421','female','1999-06-20','1977-11-10 02:37:34','2008-09-16 23:18:58'),('Izabella','Nolan','morar.selena@example.net','4efd24a9eed24e85fce3bc63496bb784cb246961',9750842001,'4167 Schuster Circles Apt. 082\nMichelleshire, PA 90747-2533','male','1974-06-03','2005-08-20 03:51:32','2016-07-09 21:36:10'),('Dennis','Hamill','maye.hessel@example.com','3c53c4495bd6a0a9639847c0747f0cc66e53e241',9421029207,'03170 Boehm Ridge\nCeliabury, NH 94397-7075','male','1990-09-28','1971-09-11 10:32:40','1977-03-27 19:53:54'),('Ahmad','Gaylord','jalon44@example.com','ff57da1da7b6cf5c930ec055ea0f6418f2079cf5',9603846120,'841 Arlie Tunnel Suite 793\nGlennaborough, ND 45218-2816','female','1996-04-02','1990-06-23 07:01:01','1979-03-14 22:50:13'),('Cicero','Fahey','schmidt.bret@example.net','5fca0901181f6cd5ee11982c1b690b6f3645e696',9702203075,'883 Matteo Ranch Apt. 491\nBashirianfurt, MN 76899-2021','female','2017-07-19','1981-08-01 09:46:27','1975-08-17 08:39:35'),('Vella','Crona','kody.steuber@example.com','8a9e3fafc95dcd97ff9cb276cd4182483d662404',9730677210,'9231 Wyman Junctions Suite 854\nPort Jesseberg, GA 92406-3175','male','2003-06-05','1984-02-02 07:04:35','1980-01-07 18:11:39'),('Brandt','Davis','ajenkins@example.com','bb6de1e8436245493c6a11dd7ef76ff68c691393',9251984441,'332 Upton Radial\nSouth Joycehaven, OK 75829-4680','female','2004-08-18','1975-10-13 14:38:01','1979-06-26 15:04:51'),('Sydney','Ernser','gianni.morissette@example.org','c63d0d3f349517112c9f2379117c5e46ec8584fb',9615982663,'214 Bailee Roads\nMillermouth, WI 14798-5257','female','1975-09-10','1993-04-29 09:23:55','1985-04-16 22:21:35'),('Nadia','Maggio','novella81@example.net','8749fa8f296e02788c4f9980713824b8720c5e73',9051195964,'8546 Schulist Ways\nJerdeport, MN 36159','male','2015-12-12','1972-07-24 18:26:03','1970-01-25 12:56:57'),('Luciano','Borer','smith.kraig@example.org','be993ea961faae90b3b90ae3415e251e26e3cda3',9628590557,'95923 Carolanne Square\nStiedemannside, CA 30076-2482','male','2021-04-08','1974-02-17 05:38:05','1975-02-28 23:59:25'),('Georgianna','Armstrong','novella.fritsch@example.org','2cdfb969e2b9b8bd258b370dc9a787326cc4d809',9732912889,'04732 Walter Cliff Apt. 692\nLeannaport, FL 06126','male','1979-03-15','1990-08-18 01:58:40','1982-12-04 19:08:08'),('Loren','Welch','mcdermott.agnes@example.net','f59972df49100b5918718f5a50b601238cbb184c',9533130860,'18680 Cory Forges Suite 205\nNarcisoton, CT 70394-0798','male','2020-08-08','2013-06-25 09:11:11','2007-06-12 23:31:52'),('Raheem','Bergnaum','vyost@example.org','bb32e4430f77c5f14bc5e5df859a152b32cb7700',9937194165,'63464 Howe Parkway\nThompsontown, CA 48699-6503','female','2017-12-09','1984-04-22 04:19:20','1971-01-22 20:55:35'),('Lorenzo','Crona','jillian.runte@example.net','4b7edcc5b7703ffa662e3050068919eaf0199965',9709479487,'7493 Crystel Passage\nCorenefort, DC 39894-0855','male','2011-06-25','2008-03-02 16:31:26','1984-03-25 19:22:11'),('Una','Zieme','weldon65@example.net','7dbf7b1d1353148680e823ad79fd5b2d19d1024a',9536713208,'6552 Marie Ferry\nRueckerberg, DE 55250-9039','female','2013-03-18','1976-04-03 08:56:30','2011-08-14 06:25:05'),('Myrtice','Hilpert','nmorar@example.com','54e033299428f1791844cddb54372925741e4c45',9438153898,'944 Mathias Spring\nPort Sonyaview, PA 54455-2206','male','1972-08-02','1985-04-11 21:59:57','2013-04-20 13:07:45'),('Lauretta','Kozey','kpredovic@example.com','c21b69d085962205b570fcbc08785a544ebbe7d4',9027167519,'588 Block Plaza Apt. 982\nVinnieberg, MT 47158','male','1992-08-30','1999-11-02 13:26:56','2018-03-06 06:58:35'),('Melyssa','Hilll','jenifer35@example.com','839d34521c19ee4d4cfbe31f0f0057f542e6bc65',9325810931,'26978 Erdman Well\nLake Vernie, HI 70468','female','2017-11-26','1987-11-08 14:31:07','1992-02-26 16:33:23'),('Randall','Bosco','tjohns@example.net','ebd15230f1481a0d5f036de03f423a4730bf7c5c',9038253677,'2520 Alexa Drive Suite 783\nCaterinastad, NV 37694','female','2009-03-01','1983-11-18 20:33:35','1994-11-26 00:03:47'),('Lily','Hintz','hmetz@example.org','cdfebdab0e698ba017dcae21b0d7c11fa8942231',9249474895,'06607 Twila Ridge\nKihnbury, ME 74054','female','1997-04-06','2018-06-09 21:17:18','1990-03-18 19:31:29'),('Friedrich','Lebsack','sgreenholt@example.org','ba758023d7c11d41143fcc0f68abc0f71b7d4f06',9812682619,'55547 Gaylord Ferry Suite 852\nLake Angel, VT 09545','female','1986-08-05','1972-10-27 06:02:03','2007-11-03 17:23:49'),('Aditya','Lang','mraz.lura@example.com','b9f6ea7fe8ea6fa7cd8562a4862dbb1d45d6ad6c',9001418942,'22657 Nitzsche Drive Suite 969\nLake Keiratown, NE 79850','male','1992-04-04','1971-07-22 08:49:24','2016-06-05 16:22:18'),('Liliane','Shanahan','gbogisich@example.com','12795b573114f66ba79c7f0e6eaf16ae029de723',9389440666,'891 Abernathy Fords\nRosenbaumland, NH 08451-0423','male','2011-12-23','1981-07-19 04:23:23','1990-04-13 10:11:42'),('Teresa','Bergstrom','lnitzsche@example.net','6cfec9bf026452c0280d083429fe63ad334c27df',9411507314,'5295 Aileen Ports Apt. 592\nAndersonton, NM 27537','male','2015-07-18','1970-01-07 22:42:15','1991-11-10 21:03:19'),('Zoe','Waters','alejandrin.koelpin@example.org','5d9271e884fdb410ed87bbc2cc50c16f2eec6d9b',9415154338,'4678 O\'Connell Meadow\nKozeytown, FL 92659-3305','female','1972-09-02','1987-06-25 16:05:26','2016-05-21 12:36:22'),('Alisa','Lakin','qrobel@example.com','3bdd81d41abd48625d939317cb3827e0b6275cac',9416908811,'255 Rubye Keys Suite 909\nNorth Desmond, OR 74340-3846','female','1973-03-29','1995-05-31 11:40:47','1985-03-07 22:36:21'),('Fabian','Hills','hudson.kaylin@example.com','4fa9a37e95400baec8d7c7b5227da04215ca6e67',9050466509,'90664 Gaston Street\nKleinfurt, VA 33350-5640','female','2014-04-12','2016-03-19 00:20:56','2004-03-22 21:20:43'),('Cecilia','Terry','vlangosh@example.com','d194067be71f4d5a23b197b231aae723644f6f0c',9563238619,'9807 Hester Port Suite 201\nNorth Alishaland, VA 09900-6027','female','1973-01-08','1984-09-17 10:10:26','2007-02-24 10:07:14'),('Margarita','Waters','bailey.pansy@example.net','172f5fbaad78085af0271be5b3023de02e74fa46',9489512424,'500 Ritchie Parks\nGageborough, WV 89303','female','2001-12-15','1980-01-31 13:46:53','1986-12-31 07:49:30'),('Noelia','McDermott','corbin59@example.com','eac081257681e757db81d013ab8ea5ac4ea62b14',9276208025,'92967 Adams Crossroad Suite 633\nEast Benjaminstad, IL 67100-2126','male','1999-05-07','2000-07-15 22:03:21','1991-11-01 22:51:58'),('Imani','Moore','bednar.dillan@example.org','ed7b648509d0b08323dd4941cdfcc788a211cab6',9058706021,'0680 Davis Mill\nWilliamsontown, OR 91082','male','1994-12-12','2002-10-01 04:40:49','1982-10-28 18:31:48'),('Valentine','Collins','lindgren.monica@example.net','d3f48cd6c15a3283a6e196cd0557990f27b5c42a',9099404784,'5884 Green Islands\nFarrellchester, NH 11211','female','1988-10-13','1999-12-03 01:30:33','1972-06-21 07:52:50'),('Damien','Barrows','benedict50@example.com','eff4a6859b1b7f4903cca6e935d64df2164568f0',9599700860,'763 McLaughlin Stream\nIrwinbury, CO 50005','female','1979-03-08','2009-06-15 16:52:34','1979-11-27 04:05:15'),('Cecile','Zieme','crona.alaina@example.com','9701aba8a3e6f7cf1a69ad5012dae46dd998c7e9',9290769706,'7694 Considine Squares\nSouth Wilhelm, OK 11530','male','1999-12-24','1980-09-20 01:31:15','1992-08-09 00:44:29'),('Alexanne','Lindgren','kaylie.kiehn@example.com','d98b2c2c8dcc20d1262edfbb9fc66cff9a581a13',9512579574,'53428 Pollich Dam Apt. 052\nEast Winfield, MO 62234-3327','female','1975-11-03','1992-05-18 13:16:17','1995-03-15 09:11:10'),('Orville','Connelly','krista44@example.com','ad0067c3be36988a1ba70401657502f61d3925ac',9872435988,'10580 Schowalter Ports\nLexietown, DE 69968-9376','female','1996-04-27','2016-05-12 17:17:30','1978-04-10 22:48:18');

INSERT INTO products
(name, description, price, catalog_id)
VALUES
	('ФрутоНяня пюре из яблок с 4 месяцев, 12 шт по 100 г', 'Однокомпонентное гипоаллергенное пюре из яблок отлично подойдет в качестве первого знакомства малыша с фруктовыми пюре "ФрутоНяня".', 341.00, 5),
	('Стиральная машина Samsung WF-60F1R2F2W, белый', 'Стиральная машина Samsung WF-60F1R2F2W с возможностью загрузки белья до 6 кг. Функциональная модель обладает всеми преимуществами современных стиральных машин.', 18954.00, 7),
	('Хороший динозавр. Дорога домой. Книга для чтения с цветными картинками | Нет автора', 'Давным-давно на земле жили динозавры. Но однажды в нашу планету врезался огромный астероид — и динозавры исчезли… А что, если бы этого не случилось? Давайте представим, что астероид пролетел мимо, и все динозавры уцелели... Читайте красочную добрую историю о маленьком апатозавре Арло и его друге — пещерном мальчике.', 236.00, 12),
	('Сланцы', 'Лучшие в мире сланцы.', 894.00, 3),
	('ASUS ROG MAXIMUS X HERO', 'Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX', 19310.00, 1),
	('Смеситель Solone LOP4-B043 для кухни с гибким изливом', 'Смеситель для кухни Solone LOP4-B043 имеет высокий поворотный гибкий излив, позволяющий пользоваться водой не только над мойкой, но и за ее пределами. Излив оборудован аэратором, два режима лейки.', 1189.00, 9),
	('Ароматизатор интерьерный Areon "Солнечный дом", 85 мл', 'Ароматизатор наполнит ваш дом свежими запахами. Вставьте палочки в ароматизатор - и волшебные ароматы распространяться по всему помещению.', 8.00, 4),
	('Жидкость стеклоомывателя Sintec Без аромата 0°C 4,5 л', 'Летняя стеклоомывающая жидкость', 232.00, 14);

INSERT INTO products (name, description, price, catalog_id, created_at, updated_at) VALUES ('numquam','Dolorem inventore maiores nihil porro. Et voluptas doloremque quae quia quisquam asperiores. Recusandae ut aut aut eaque consectetur tempora totam. Autem et fuga quo quia rerum ut.',38321.45,7,'2020-02-26 08:13:37','1980-02-21 22:16:47'),('nobis','Omnis ut omnis ad iste laboriosam. Eum consectetur voluptas neque sint libero ut placeat. Aut voluptas amet iure iste esse.',36515.94,14,'2003-10-26 18:56:01','1979-12-14 16:04:03'),('sunt','Quis nostrum et voluptas hic. Praesentium ut necessitatibus quia aut quia. Dolorum reprehenderit ut mollitia aut et atque illo. Sequi consequatur qui facere quia.',46751.72,14,'1997-08-15 01:22:48','1997-11-12 18:05:25'),('voluptates','Repellat soluta vel provident asperiores ratione aperiam. Illo quae ut sint quas. Ipsum ratione amet laudantium et.',49934.89,14,'2006-09-06 15:13:23','2018-02-21 10:01:44'),('ut','Iste amet aut autem itaque maiores iure distinctio. Et dolorum omnis consectetur veritatis eaque. Sit ut magnam quia cum totam porro sed magnam. Culpa ut delectus omnis non.',5511.38,11,'1992-01-22 21:00:28','2015-08-17 07:30:37'),('eius','Molestiae consequatur numquam qui autem hic aperiam a numquam. Aut voluptatum possimus velit est delectus omnis. Labore voluptatum beatae impedit consequatur quia sed accusantium culpa.',42813.56,12,'2006-09-15 09:55:52','1997-05-18 08:38:12'),('unde','Error odit ut nihil necessitatibus ut ducimus. Mollitia enim aliquam in similique. Distinctio earum nisi quo rerum veritatis cumque quo. Ducimus error possimus et quia iusto.',7913.09,7,'1976-03-07 05:28:13','1995-08-13 07:18:42'),('vitae','Dolores quia laboriosam perspiciatis velit et corporis. Quo nam blanditiis neque. Voluptas eum architecto voluptatem.',35235.92,14,'1976-09-28 00:47:44','2004-10-12 13:16:22'),('quia','Est ipsa eum fugiat delectus accusantium. Omnis omnis vero non. Sit libero hic et sed praesentium voluptate hic enim.',38710.27,6,'1979-10-23 00:48:16','1988-05-08 05:08:49'),('adipisci','Id voluptatem nobis culpa nesciunt fugit tenetur repellendus. Perspiciatis soluta necessitatibus laboriosam et nostrum. Eveniet autem eius eum voluptatem est molestiae officia odio.',35031.31,4,'1986-01-22 16:53:38','1979-03-14 16:34:47'),('deserunt','Architecto earum occaecati laboriosam optio laudantium cupiditate. Et neque qui molestias asperiores provident officiis est. Omnis qui porro odio dolor aspernatur. Molestiae voluptate fugit sit totam vitae non et. Tempore dolor delectus autem.',31687.76,3,'2003-01-09 13:28:39','2020-02-26 00:15:12'),('cum','Earum veniam laboriosam nostrum ipsam. Rerum fugit omnis labore error. Et corporis animi accusamus maiores delectus.',38337.48,3,'1980-07-17 18:26:25','1976-06-01 19:05:35'),('excepturi','Veritatis ut esse fuga voluptas illum vero velit. Fuga omnis ex ipsam reiciendis atque dolores et. Enim eveniet labore magnam id cupiditate non. Non non ipsam aut.',25477.79,17,'1982-09-07 07:05:36','1971-05-04 08:03:34'),('quisquam','Omnis perspiciatis enim nam ipsa. Voluptatem quia ut adipisci. Architecto consectetur odit aut suscipit quae dolores.',41032.09,9,'1984-08-25 14:38:11','1997-04-04 17:44:43'),('ipsa','Id voluptates rerum maxime possimus. Est error facilis similique a animi. Itaque velit id ex distinctio. Unde repudiandae ipsum aut molestias aut perferendis.',42490.13,0,'1997-11-02 14:39:47','1990-06-28 14:44:59'),('dolor','Nihil qui esse qui ullam. Sapiente sint ad aliquam. Nam tenetur dolorem qui non et nisi expedita. Qui molestiae ducimus voluptas sapiente ratione.',21411.75,18,'1986-03-08 00:08:59','2012-04-29 11:54:01'),('voluptatem','Aspernatur quis in occaecati ea nostrum maiores. Vitae quia facilis dolorem. Accusantium maiores maxime enim corrupti omnis. Eum ratione quasi aut repudiandae eligendi maxime.',39684.50,9,'2002-08-05 03:42:41','1997-01-02 00:50:40'),('corrupti','Molestias qui omnis nesciunt nostrum reprehenderit unde. Rerum aut animi aut magnam quas natus quo. Recusandae qui saepe doloribus ratione consequatur.',33558.20,19,'1990-12-31 07:24:47','1984-11-26 22:49:01'),('molestias','Enim nobis odio perferendis vero possimus a minima. Sed iure natus velit. Mollitia libero numquam consectetur incidunt fuga reiciendis. Enim eius minima quidem fugiat eius.',8025.00,3,'2015-12-23 17:15:04','1986-09-29 15:49:14'),('et','Sit dolor minima ut. Deleniti minima quam eos earum asperiores ipsum. Molestiae ut quo ullam veniam reiciendis. Omnis atque suscipit rerum voluptatem.',7477.38,16,'1980-01-02 11:05:56','1998-09-28 09:50:19'),('repellendus','Sequi enim quod inventore velit. Quod ut ipsam voluptas pariatur inventore quia ut incidunt.',28144.36,20,'2002-09-09 16:29:33','2005-10-19 06:16:28'),('veritatis','In sit sapiente eum fuga a. Consequatur et nemo voluptatibus aut iusto beatae. Vel dolores eum repudiandae aliquid velit. Nesciunt distinctio quis a.',3307.30,13,'2021-04-24 18:07:45','1987-04-03 13:04:31'),('ut','Quidem voluptas voluptate autem veritatis quia ut. Molestiae laboriosam aut et laborum ratione vitae quidem. Ducimus eligendi adipisci nulla libero. Asperiores corrupti dolore maiores neque eligendi est voluptatem minus. Eum et consequatur commodi recusandae minus corporis corporis iste.',5836.93,7,'2014-02-14 18:11:00','2007-06-18 17:45:46'),('assumenda','Aut in nemo doloremque ullam eligendi incidunt veritatis ab. Suscipit laborum cumque quia. Iure temporibus asperiores a quibusdam dolor voluptatem officia. Occaecati eligendi autem excepturi eum aut rerum iusto.',40626.00,14,'2009-06-13 19:40:46','1987-05-06 17:16:58'),('praesentium','Et vero tenetur dolor placeat mollitia quod. Vitae voluptatem earum alias voluptatem aut qui ipsa. Mollitia exercitationem temporibus enim rerum quo. Animi voluptas sit non alias vero rerum.',14274.95,13,'2018-05-12 00:24:20','2008-01-21 18:04:43'),('itaque','Qui rerum sapiente rerum. Aut repellat et placeat laborum totam id. Eum commodi modi natus et voluptatem quis. Totam molestiae molestiae voluptates laudantium non dolore.',83477.41,12,'1981-11-03 19:33:49','1992-02-15 03:11:29'),('molestiae','Dolor aperiam voluptatem unde. Consequatur odio est nihil voluptate autem sed et.',263645.14,2,'2000-07-26 15:03:45','2005-04-24 21:33:26'),('commodi','Provident ducimus modi porro minima nulla commodi. Nisi maxime voluptatem nisi minima doloremque rerum. Quis non ut aperiam sit quam.',233717.91,4,'2015-10-26 05:38:54','1972-05-01 13:04:50'),('illum','Nostrum sit enim sed laboriosam. Vitae eum recusandae magnam ipsum ut et. Quia doloremque voluptas esse dolores. Voluptatem ut impedit nisi quibusdam.',245962.69,18,'1992-07-01 02:28:21','1984-07-16 08:56:18'),('soluta','In sit quas doloribus praesentium error consectetur in exercitationem. Illum occaecati ea perspiciatis quia voluptatem ea quas rerum. Accusantium facere debitis dolor voluptatum non est aut. Vel facilis qui nihil.',237517.68,15,'1999-02-26 10:12:21','1996-11-17 20:41:32'),('sed','Similique sit illo expedita debitis sunt quod. Et voluptatem exercitationem rerum porro ullam illum sint. Enim aspernatur qui quasi quasi ipsam praesentium fugit.',59191.10,14,'1989-07-08 08:20:24','1989-12-26 00:39:43'),('distinctio','Beatae minima perferendis est. Beatae blanditiis sed et magnam ea perferendis. Et voluptas sint vero quidem aut. Hic quas quia reprehenderit quisquam reprehenderit error ut. Delectus fugiat minus voluptatibus delectus.',438065.74,16,'2019-01-23 10:05:09','1985-05-18 00:37:11'),('odit','In quos ut error vel iure accusamus. Qui qui corrupti qui laudantium non iure placeat. Delectus qui quas in cumque libero laboriosam dolorum.',360454.33,13,'1991-07-28 09:25:01','1985-04-27 15:11:28'),('recusandae','Dolores alias quia non odit. Voluptas repudiandae laborum quasi aliquam minima dicta. Aliquam ut officiis error labore beatae ea quia. Voluptatem et magnam voluptatum minus.',281920.70,8,'2002-12-03 03:09:44','2012-03-15 12:38:49'),('sed','Saepe sed quo quidem vero. Adipisci qui est odit earum. Qui tempore ea quisquam et non.',57816.80,6,'1995-08-19 14:41:44','1977-02-20 16:30:45'),('sit','Distinctio et qui autem. Laboriosam ut officia deleniti qui adipisci reprehenderit non. Aut sed architecto ea quasi ut architecto sapiente.',314418.02,11,'2006-06-24 14:15:54','1985-09-12 00:33:34'),('et','Numquam facere laudantium autem accusamus et consequatur. Culpa mollitia et minima. Quo dolorem debitis quis temporibus. Voluptates et labore dolorem deleniti omnis saepe. Praesentium quia ex sed unde nemo hic voluptatem accusantium.',153219.46,13,'1978-01-25 09:47:43','2010-03-16 10:58:17'),('autem','Similique quo minima quia libero eos. Eos recusandae veritatis magni earum numquam. Pariatur vel voluptas et vitae.',486928.44,1,'2004-12-06 01:44:01','2006-08-29 22:30:06'),('reprehenderit','Qui non qui qui est ipsum qui accusantium. Est corporis dolores in officiis illo. Qui architecto dolores hic minus ut qui provident.',82748.00,18,'1997-04-19 14:56:05','2016-08-06 19:43:17'),('dolores','Non animi iste officiis recusandae quaerat rerum aut inventore. Porro possimus et quisquam est magni vitae. Rerum aut modi autem maiores. Eius fugiat quas culpa rerum facere quibusdam cumque.',351750.51,16,'1988-07-11 12:18:59','2003-09-09 11:59:01'),('est','Repellat ad natus est similique provident officia numquam. Cumque nihil magni omnis voluptas dolores. Quod dolorum sit excepturi debitis voluptate in.',232379.53,6,'2004-03-24 21:43:06','1990-06-11 02:42:32'),('soluta','Delectus rerum nisi possimus odit doloremque eius debitis. Ea ratione expedita et.',161735.42,6,'2017-06-18 09:06:16','2012-09-19 12:02:09'),('dolorem','Dignissimos repellat aspernatur ab iure. Et sed nostrum ipsam excepturi et totam et. Repellendus ut quia ipsum. Non sint doloremque ut totam ducimus nisi.',361183.00,16,'2017-05-04 00:11:56','2009-10-07 15:57:23'),('numquam','Harum vero reprehenderit ex iure. A dolorum assumenda hic doloremque. Eos sint maxime numquam velit quae quod veritatis. Distinctio quis sint repellat qui.',409415.64,15,'1971-11-10 02:40:19','1992-09-17 20:48:38'),('dolores','Laboriosam earum illum quia nulla expedita qui non. Voluptas dolores porro dicta sed omnis praesentium.',469449.22,20,'1970-07-02 08:33:29','1986-05-23 18:50:17'),('tempore','Eaque iure et sint. Quibusdam unde eligendi fugiat illum aut adipisci sapiente assumenda. Quam eveniet facilis molestias.',236458.00,16,'2009-10-02 17:03:21','2015-05-25 14:50:43'),('quos','Tempore dicta quia et eos voluptas maiores. Quis consequatur ea aut libero nulla et. Mollitia perferendis non vero fugiat est qui voluptatem.',301764.44,10,'1992-05-04 18:09:19','1980-02-03 00:16:50'),('deleniti','Nihil eos est quis enim voluptatem. Sit cumque quidem in repellat quaerat. Ut amet ducimus sit explicabo eos excepturi sed.',332166.18,6,'2007-10-30 22:33:30','2003-08-10 16:21:54'),('quia','Ea culpa sed nisi magni. Id enim qui cumque quia. Eveniet quae qui voluptas in quisquam quam officia quo.',294674.07,12,'2011-02-27 16:35:04','2020-10-01 18:18:31'),('nesciunt','Ipsum similique et quia sed hic. Distinctio aut quo iusto saepe. Molestias repudiandae possimus nam aspernatur blanditiis. Quibusdam sit aspernatur reiciendis numquam at at.',136487.19,2,'1980-01-08 14:44:30','2003-07-15 08:59:41');

INSERT INTO bank_cards 
(user_id, bank_card_number, emitter, payment_system, beginning_date, expiration_date)
VALUES
	(29, '4921492185934449', 'Sberbank', 'MasterCard', '2020-12-23', '2024-07-05'),
	(2, '4985792348574875', 'VTB Bank', 'Visa', '2018-12-13', '2022-09-04'),
	(3, '4839584495548493', 'Gazprombank', 'MasterCard', '2017-12-15', '2023-01-03'),
	(4, '9847502948753857', 'PromSvyaz Bank', 'Visa', '2019-12-09', '2025-09-11'),
	(17, '0924875209875975', 'Alfa Bank', 'MasterCard', '2021-12-06', '2026-06-10'),
	(9, '9879548749874878', 'Otkritie Financial Corporation Bank', 'Mir', '2020-12-10', '2026-06-05'),
	(12, '3948345954939932', 'Russian Agricultural Bank', 'MasterCard', '2018-10-22', '2022-05-12'),
	(25, '3202934802934893', 'UniCredit Bank', 'Mir', '2020-04-03', '2024-12-17'),
	(30, '4985039584309584', 'AO Raiffeisenbank', 'MasterCard', '2021-12-18', '2025-09-24'),
	(5, '9594393944472398', 'Rosbank', 'MasterCard', '2019-04-10', '2023-10-19'),
	(45, '4095830458430583', 'Sberbank', 'MasterCard', '2020-12-23', '2024-07-05'),
	(13, '0956459064598500', 'VTB Bank', 'Visa', '2018-12-13', '2022-09-04'),
	(37, '0943909930940399', 'Gazprombank', 'MasterCard', '2017-12-15', '2023-01-03'),
	(22, '9094903949309494', 'PromSvyaz Bank', 'Visa', '2019-12-09', '2025-09-11'),
	(47, '09430943-0940399', 'Alfa Bank', 'MasterCard', '2021-12-06', '2026-06-10'),
	(46, '4095830850495458', 'Otkritie Financial Corporation Bank', 'Mir', '2020-12-10', '2026-06-05'),
	(19, '0345830958349899', 'Russian Agricultural Bank', 'MasterCard', '2018-10-22', '2022-05-12'),
	(28, '5847645987689457', 'UniCredit Bank', 'Mir', '2020-04-03', '2024-12-17'),
	(1, '9874875487589475', 'AO Raiffeisenbank', 'MasterCard', '2021-12-18', '2025-09-24'),
	(31, '4584353905840588', 'Rosbank', 'MasterCard', '2019-04-10', '2023-10-19');

-- INSERT INTO users_purchases 
-- (user_id, pickup_point_id, product_id)
-- (1, '9874875487589475', 'AO Raiffeisenbank', 'MasterCard', '2021-12-18', '2025-09-24'),
	
INSERT INTO pickup_points
	(id, phone, adress)
VALUES
	(1, '8655508861', 'обл. Московская, г. Балашиха, ул. Свердлова, д. 16/5'),
	(2, '8954385985', 'обл. Московская, г. Балашиха, ш. Щелковское, д. 98'),
	(3, '9948350948', 'Россия, 143900, обл. Московская, г. Балашиха, ул. Дмитриева, д. 6'),
	(4, '9984984484', 'Россия, Московская область, Балашиха, Звёздная улица, 10'),
	(5, '9988884848', 'г. Москва, ул. Малая Пироговская улица, д. 17'),
	(6, '9395834958', 'г. Москва, пер. Хользунова, д. 6'),
	(7, '8495849588', 'г. Москва, наб. Пречистенская, д. 5'),
	(8, '9409584309', 'г. Москва, ул. улица Багрицкого, д. 3 корп. 1'),
	(9, '9498594588', 'г. Москва, ул. улица Боженко, д. 4'),
	(10, '9989459858', 'г. Москва, ул. Нежинская, д. 13');

INSERT INTO purchases 
	(user_id, pickup_point_id, product_id)
VALUES 
	('24','4','25'),
	('27','4','18'),
	('6','9','25'),
	('35','9','32'),
	('8','1','52'),
	('33','2','11'),
	('47','1','23'),
	('24','1','18'),
	('45','5','40'),
	('33','1','43'),
	('49','9','16'),
	('17','10','50'),
	('23','6','49'),
	('30','5','42'),
	('48','8','11'),
	('16','1','22'),
	('24','5','51'),
	('46','9','47'),
	('49','5','6'),
	('41','9','20'),
	('3','2','27'),
	('13','3','14'),
	('24','7','39'),
	('47','7','17'),
	('47','1','17'),
	('37','8','42'),
	('17','5','41'),
	('13','1','14'),
	('50','10','12'),
	('4','9','43'),
	('5','4','24'),
	('28','4','29'),
	('49','8','40'),
	('22','1','44'),
	('13','2','51'),
	('24','3','41'),
	('1','6','27'),
	('12','1','49'),
	('48','7','1'),
	('33','3','22'),
	('3','8','27'),
	('50','1','38'),
	('9','3','34'),
	('28','1','41'),
	('5','5','32'),
	('5','3','14'),
	('8','8','38'),
	('15','3','13'),
	('24','2','25'),
	('2','8','46'),
	('28','5','49'),
	('19','1','15'),
	('45','1','46'),
	('25','2','46'),
	('16','3','31'),
	('38','2','45'),
	('40','6','50'),
	('20','1','28'),
	('13','1','14'),
	('11','5','45'),
	('19','9','11'),
	('10','5','30'),
	('9','2','22'),
	('37','1','49'),
	('8','8','52'),
	('34','9','21'),
	('16','6','30'),
	('46','6','43'),
	('39','5','53'),
	('26','7','36'),
	('10','9','48'),
	('20','3','2'),
	('49','3','42'),
	('13','7','12'),
	('31','5','1'),
	('41','1','54'),
	('48','8','35'),
	('40','1','27'),
	('28','9','53'),
	('49','5','5'),
	('20','8','4'),
	('49','7','14'),
	('4','2','13'),
	('4','3','10'),
	('33','2','42'),
	('37','4','24'),
	('48','2','20'),
	('45','10','17'),
	('22','2','37'),
	('43','10','20'),
	('27','9','48'),
	('5','3','26'),
	('33','2','18'),
	('21','1','1'),
	('37','9','2'),
	('16','1','17'),
	('40','9','25'),
	('13','6','11'),
	('13','2','10'),
	('13','2','12'),	
	('38','3','5');

-- SELECT * FROM catalogs;
-- SELECT * FROM users;
-- SELECT * FROM products;
-- SELECT * FROM bank_cards;
-- SELECT * FROM pickup_points;
-- SELECT * FROM purchases;

-- Скрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы);
-- Джоин
SELECT 
	users.id AS `User ID`,
	CONCAT(users.firstname , ' ' , users.lastname) AS `Name`,
	bank_cards.bank_card_number AS `Bank Card Number`,
	bank_cards.emitter AS `Bank Card Emitter`,
	bank_cards.expiration_date AS `Bank Card Expiration Date`
FROM users
JOIN bank_cards ON bank_cards.user_id=users.id
GROUP BY users.id
ORDER BY users.id;

-- Вложенные таблицы (Вывести все покупки пользователя с ID 13 из раздела автотовары (ID 14)
SELECT -- Я так понимаю, этот скрипт написан верно, но в самих таблицах есть какая-то проблема, которые приводит к неправильному результату этого скрипта. Всё перепробовал, но не смог решить проблему.
	purchases.product_id
FROM purchases
WHERE purchases.user_id=13
AND purchases.product_id IN 
	(SELECT id FROM catalogs WHERE catalogs.id = 14)
GROUP BY purchases.user_id
ORDER BY purchases.user_id;

-- Представления (минимум 2);
-- Выборка пользователей с ID больше 30
CREATE OR REPLACE VIEW view1 
AS SELECT 
id,  
CONCAT(users.firstname , ' ' , users.lastname) AS `Name`
FROM users WHERE id > 30;

SELECT * FROM view1;

-- Все продукты из раздела "Детские товары"  (ID 5)
CREATE OR REPLACE VIEW view2
AS SELECT 
	products.name AS `Товар`,
	products.price AS `Цена (руб.)`,
	catalogs.name AS `Раздел`
FROM products
	JOIN catalogs ON catalogs.id = 5;

SELECT * FROM view2;

-- Хранимые процедуры / триггеры;
-- Триггер
DROP TRIGGER IF EXISTS trigger_childrens_products_no_more_than_30000;
DELIMITER //
CREATE TRIGGER trigger_childrens_products_no_more_than_30000 
BEFORE INSERT 
ON products FOR EACH ROW
BEGIN
	IF NEW.price > 30000.00 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Триггер: у нас демократичные цены на детские товары. Товары из данной категории не могут стоить более 30 тысяч рублей';
	END IF;
END//

DELIMITER ;
SHOW TRIGGERS;

INSERT INTO products 
(name, description, price, catalog_id)
VALUES
('Детская коляска 1000 ECONOMY', 'Супердорогущая детская коляска', 29000.00, 5);
('Детская коляска PLATINUM 2000+ PRO PREMIUM', 'Супердорогущая детская коляска', 30001.00, 5);

-- Процедура
-- Процедура склеивает две таблицы по двум столбцам. Процедура, наверное, бессмысленная, но это не функуция, так как используется один раз для конкретной задачи, в то время как одна и та же функция может неоднократно применяться в разных местах.
DROP PROCEDURE IF EXISTS select_from_tables;
DELIMITER //
CREATE PROCEDURE select_from_tables()
	(SELECT firstname, lastname FROM users)
	UNION
	(SELECT emitter, payment_system FROM bank_cards);
DELIMITER ;

CALL select_from_tables();