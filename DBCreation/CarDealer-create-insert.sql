DROP TABLE IF EXISTS sprzedaz;
DROP TABLE IF EXISTS wyposazenie_samochodu;
DROP TABLE IF EXISTS oferta_dealera;
DROP TABLE IF EXISTS katalog_dealera;
DROP TABLE IF EXISTS dodatkowe_wyposazenie;
DROP TABLE IF EXISTS osobowy;
DROP TABLE IF EXISTS ciezarowy;
DROP TABLE IF EXISTS klient;
DROP TABLE IF EXISTS dealer;
DROP TABLE IF EXISTS samochod;
DROP TABLE IF EXISTS model;
DROP TABLE IF EXISTS typ_silnika;
DROP TABLE IF EXISTS marka;
DROP PROCEDURE IF EXISTS usp_dodaj_samochod;
DROP PROCEDURE IF EXISTS usp_sprzedaz;
DROP PROCEDURE IF EXISTS usp_usun_z_katalogu;
DROP PROCEDURE IF EXISTS usp_zmien_przebieg;
DROP PROCEDURE IF EXISTS usp_srednia_cena;
DROP FUNCTION IF EXISTS ufn_datecompare;
DROP FUNCTION IF EXISTS ufn_datecompare2;
DROP FUNCTION IF EXISTS ufn_dealermodelu;
DROP VIEW IF EXISTS sprzedaze;
DROP TRIGGER IF EXISTS check_engine;

CREATE TABLE marka
(
    nazwa VARCHAR(20) PRIMARY KEY,
    rok_zalozenia DATE NOT NULL
);
GO

CREATE FUNCTION dbo.ufn_datecompare
	(
	@date DATE,
	@name VARCHAR(20)
	)
	RETURNS INT
AS
BEGIN
		IF @date >(SELECT rok_zalozenia
					FROM marka
					WHERE nazwa = @name)
			RETURN 1
		RETURN 0
	END;
GO


CREATE TABLE typ_silnika
(
    identyfikator INT IDENTITY(1,1) PRIMARY KEY,
    rodzaj_paliwa VARCHAR(max) NOT NULL CHECK(rodzaj_paliwa IN('Benzyna','Olej Napędowy','Hybrydowy','Elektryczny')),
    opis_parametrów VARCHAR(max) 
);
GO
CREATE TABLE model
(
    identyfikator INT IDENTITY(1,1) PRIMARY KEY,
    nazwa VARCHAR(max) NOT NULL,
    rok_wprowadzenia DATE NOT NULL ,
    marka_modelu VARCHAR(20) REFERENCES marka(nazwa),
    silnik_modelu INT REFERENCES typ_silnika(identyfikator),
    id_poprzednik  INT REFERENCES  model(identyfikator),
	CONSTRAINT new_constraint CHECK (dbo.ufn_datecompare(rok_wprowadzenia,marka_modelu)=1)
);

GO

CREATE FUNCTION dbo.ufn_datecompare2
	(
	@date DATE,
	@id INT
	)
	RETURNS INT
AS
BEGIN
		IF @date >(SELECT rok_wprowadzenia
					FROM model
					WHERE identyfikator = @id)
			RETURN 1
		RETURN 0
	END;
GO

CREATE UNIQUE INDEX idx_un ON model(id_poprzednik) WHERE id_poprzednik IS NOT NULL;

CREATE TABLE osobowy
(
    id_osobowy INT REFERENCES model(identyfikator),
    pojemnosc_bagaznika INT NOT NULL,
    liczba_pasazerow INT NOT NULL,
    CONSTRAINT pk_osobowy PRIMARY KEY(id_osobowy)
);
CREATE TABLE ciezarowy
(
    id_ciezarowy INT REFERENCES model(identyfikator),
    ladownosc NUMERIC NOT NULL,
    CONSTRAINT pk_ciezarowy PRIMARY KEY(id_ciezarowy)
);
CREATE TABLE dodatkowe_wyposazenie
(
    nazwa VARCHAR(30) PRIMARY KEY 
);
CREATE TABLE samochod
(
    vin VARCHAR(17) PRIMARY KEY,
    kraj_pochodzenia VARCHAR(max),
    przebieg INT NOT NULL,
    skrzynia_biegow VARCHAR(max) NOT NULL CHECK (skrzynia_biegow IN('manualna','automatyczna')),
    rok_produkcji DATE NOT NULL,
    silnik_samochodu INT REFERENCES typ_silnika(identyfikator),
    model_samochodu INT REFERENCES model(identyfikator),
	CONSTRAINT car_proDate CHECK(dbo.ufn_datecompare2(rok_produkcji,model_samochodu)=1)

);
CREATE TABLE wyposazenie_samochodu
(
    vin_samochodu VARCHAR(17) REFERENCES samochod(vin),
    nazwa_wyposazenia VARCHAR(30) REFERENCES dodatkowe_wyposazenie(nazwa),
    CONSTRAINT pk_wyposazenie PRIMARY KEY(vin_samochodu,nazwa_wyposazenia)
);
CREATE TABLE dealer
(
    nazwa VARCHAR(30) PRIMARY KEY,
    adres VARCHAR(max) NOT NULL
);
CREATE TABLE klient
(
    identyfikator INT IDENTITY(1,1) PRIMARY KEY,
    imie VARCHAR(max) NOT NULL,
    nazwisko VARCHAR(max) NOT NULL
);
CREATE TABLE oferta_dealera
(
    vin_samochodu VARCHAR(17) REFERENCES samochod(vin),
    nazwa_dealera VARCHAR(30) REFERENCES dealer(nazwa),
    CONSTRAINT pk_oferta PRIMARY KEY(vin_samochodu)
);
CREATE TABLE katalog_dealera
(
    katalog_modele INT REFERENCES model(identyfikator),
    katalog_dealer VARCHAR(30) REFERENCES dealer(nazwa),
    CONSTRAINT pk_katalog PRIMARY KEY(katalog_modele,katalog_dealer)
);
CREATE TABLE sprzedaz
(
    cena MONEY NOT NULL,
    data DATE NOT NULL,
    id_klienta INT REFERENCES klient(identyfikator),
    nazwa_dealera VARCHAR(30) REFERENCES dealer(nazwa),
    id_samochodu VARCHAR(17) REFERENCES samochod(vin),
    CONSTRAINT pk_sprzedaz PRIMARY KEY(data,id_klienta,nazwa_dealera,id_samochodu)
);
GO

CREATE TRIGGER check_engine
ON samochod
AFTER INSERT, UPDATE
AS
	IF NOT EXISTS(SELECT i.vin
					FROM inserted i
						JOIN model m
						 ON m.identyfikator = i.model_samochodu
					WHERE i.silnik_samochodu = m.silnik_modelu
					) 
	BEGIN
	PRINT 'Dany silnik nie jest dostępny dla tego modelu'
	ROLLBACK TRANSACTION;
	END;
	GO

INSERT INTO marka VALUES('Alfa Romeo','1910');
INSERT INTO marka VALUES('Volkswagen','1937');
INSERT INTO marka VALUES('Renault','1898');
INSERT INTO marka VALUES('Scania','1891');
INSERT INTO marka VALUES('Honda','1948');
INSERT INTO marka VALUES('Toyota','1937');
INSERT INTO marka VALUES('Audi','1909');
INSERT INTO marka VALUES('Porsche','1931');
INSERT INTO marka VALUES('Ford','1903');
INSERT INTO marka VALUES('Volvo','1927');

INSERT INTO typ_silnika VALUES('Benzyna','R6,Pojemność 2.6l, Moc 276kM');
INSERT INTO typ_silnika VALUES('Benzyna','R4,Pojemność 1.4l, Moc 75kM');
INSERT INTO typ_silnika VALUES('Benzyna','R4,Pojemność 1.8l, Moc 120kM');
INSERT INTO typ_silnika VALUES('Benzyna','V8,Pojemność 5.0l, Moc 340kM');
INSERT INTO typ_silnika VALUES('Benzyna','V6,Pojemność 3.0l, Moc 250kM');
INSERT INTO typ_silnika VALUES('Olej napędowy','R4,Pojemność 1.9l, Moc 105kM');
INSERT INTO typ_silnika VALUES('Olej napędowy','R4,Pojemność 1.5l, Moc 70kM');
INSERT INTO typ_silnika VALUES('Olej napędowy','V6,Pojemność 2.5l, Moc 180kM');
INSERT INTO typ_silnika VALUES('Olej napędowy','V8,Pojemność 4.0l, Moc 200kM');
INSERT INTO typ_silnika VALUES('Olej napędowy','R4,Pojemność 2.0l, Moc 130kM');

INSERT INTO model VALUES('Brera','2003','Alfa Romeo',3,null);
INSERT INTO model VALUES('Civic mk.5','1998','Honda',2,null);
INSERT INTO model VALUES('Golf mk.4','1992','Volkswagen',6,null);
INSERT INTO model VALUES('A3 ','1998','Audi',10,null);
INSERT INTO model VALUES('Focus','1995','Ford',2,null);
INSERT INTO model VALUES('993','2006','Porsche',1,null);
INSERT INTO model VALUES('S60','2004','Volvo',5,null);
INSERT INTO model VALUES('Yaris','2000','Toyota',2,null);
INSERT INTO model VALUES('Laguna','1994','Renault',8,null);
INSERT INTO model VALUES('Laguna mk.2','2001','Renault',6,9);
INSERT INTO model VALUES('FH16','2000','Volvo',8,null);
INSERT INTO model VALUES('R620','1993','Volvo',8,null);
INSERT INTO model VALUES('G290','1992','Renault',9,null);
INSERT INTO model VALUES('143','1982','Scania',9,null);
INSERT INTO model VALUES('Magnum','2003','Renault',8,null);
INSERT INTO model VALUES('R124L','2010','Scania',9,null);
INSERT INTO model VALUES('FH12','1980','Volvo',8,null);
INSERT INTO model VALUES('Premium Route','2007','Renault',4,null);
INSERT INTO model VALUES('FM10','1983','Volvo',5,null);
INSERT INTO model VALUES('Kerax','2014','Renault',9,null);

INSERT INTO osobowy VALUES(1,300,4);
INSERT INTO osobowy VALUES(2,200,5);
INSERT INTO osobowy VALUES(3,430,5);
INSERT INTO osobowy VALUES(4,380,5);
INSERT INTO osobowy VALUES(5,280,5);
INSERT INTO osobowy VALUES(6,100,2);
INSERT INTO osobowy VALUES(7,600,5);
INSERT INTO osobowy VALUES(8,150,4);
INSERT INTO osobowy VALUES(9,460,5);
INSERT INTO osobowy VALUES(10,410,5);

INSERT INTO ciezarowy VALUES(11,5.0);
INSERT INTO ciezarowy VALUES(12,7.0);
INSERT INTO ciezarowy VALUES(13,11.00);
INSERT INTO ciezarowy VALUES(14,8.3);
INSERT INTO ciezarowy VALUES(15,3.6);
INSERT INTO ciezarowy VALUES(16,6.7);
INSERT INTO ciezarowy VALUES(17,9.1);
INSERT INTO ciezarowy VALUES(18,5.8);
INSERT INTO ciezarowy VALUES(19,6.3);
INSERT INTO ciezarowy VALUES(20,9.3);

INSERT INTO dodatkowe_wyposazenie VALUES('Czujniki cofania');
INSERT INTO dodatkowe_wyposazenie VALUES('Tempomat');
INSERT INTO dodatkowe_wyposazenie VALUES('Czujniki deszczu');
INSERT INTO dodatkowe_wyposazenie VALUES('Klimatyzacja');
INSERT INTO dodatkowe_wyposazenie VALUES('Wspomaganie kierownicy');
INSERT INTO dodatkowe_wyposazenie VALUES('Zamek centralny');
INSERT INTO dodatkowe_wyposazenie VALUES('Skórzana tapicerka');
INSERT INTO dodatkowe_wyposazenie VALUES('Kierownica multimedialna');
INSERT INTO dodatkowe_wyposazenie VALUES('Światła ksenonowe');
INSERT INTO dodatkowe_wyposazenie VALUES('Alufelgi');

INSERT INTO samochod VALUES('53583868545080825','Polska',398715,'manualna','2005',3,1);
INSERT INTO samochod VALUES('71206667173749805','Niemcy',393766,'automatyczna','2000',2,2);
INSERT INTO samochod VALUES('41762623850489997','Francja',239200,'manualna','1997',6,3);
INSERT INTO samochod VALUES('28597512667119666','Rosja',165673,'manualna','2001',10,4);
INSERT INTO samochod VALUES('50771862141656972','Ukraina',175596,'automatyczna','1996',2,5);
INSERT INTO samochod VALUES('50354729546078273','Czechy',113672,'manualna','2008',1,6);
INSERT INTO samochod VALUES('10105484846689802','Włochy',234312,'automatyczna','2006',5,7);
INSERT INTO samochod VALUES('27057797557734859','Wielka Brytania',183863,'automatyczna','2002',2,8);
INSERT INTO samochod VALUES('86642245931626140','Japonia',139111,'automatyczna','1997',8,9);
INSERT INTO samochod VALUES('95191600989517207','Stany Zjednoczone',324111,'manualna','2004',6,10);


INSERT INTO wyposazenie_samochodu VALUES('53583868545080825','Czujniki deszczu');
INSERT INTO wyposazenie_samochodu VALUES('71206667173749805','Tempomat');
INSERT INTO wyposazenie_samochodu VALUES('41762623850489997','Klimatyzacja');
INSERT INTO wyposazenie_samochodu VALUES('28597512667119666','Skórzana tapicerka');
INSERT INTO wyposazenie_samochodu VALUES('50771862141656972','Kierownica multimedialna');
INSERT INTO wyposazenie_samochodu VALUES('50354729546078273','Alufelgi');
INSERT INTO wyposazenie_samochodu VALUES('10105484846689802','Zamek centralny');
INSERT INTO wyposazenie_samochodu VALUES('27057797557734859','Czujniki cofania');
INSERT INTO wyposazenie_samochodu VALUES('86642245931626140','Światła ksenonowe');
INSERT INTO wyposazenie_samochodu VALUES('95191600989517207','Wspomaganie kierownicy');

INSERT INTO dealer VALUES('CarCom','ul. Askenazego Szymona 53,Warszawa');
INSERT INTO dealer VALUES('FastSale','ul. Rezedowa 20,Wrocław');
INSERT INTO dealer VALUES('InterCar','ul. Sędziwoja 138,Poznań');
INSERT INTO dealer VALUES('CheapWheels','ul. Niedzicka 105,Kraków');
INSERT INTO dealer VALUES('ValueVehicles','ul. Piastowska 82,Dobrodzień');
INSERT INTO dealer VALUES('FastAndCheap','ul. Dolna 81,Wrocław');
INSERT INTO dealer VALUES('AndMar','ul. Zagajnikowa 61,Warszawa');
INSERT INTO dealer VALUES('BullitCars','ul. Linki Bogumiła 141,Olsztyn');
INSERT INTO dealer VALUES('DriveForCheap','ul. Rozłucka 145,Warszawa');
INSERT INTO dealer VALUES('CarsForCents','ul. Witolda 135,Łódź');

INSERT INTO klient VALUES('Lew','Wieczorek');
INSERT INTO klient VALUES('Cyryl','Kucharski');
INSERT INTO klient VALUES('Łucja','Wysocka');
INSERT INTO klient VALUES('Tekla','Czerwińska');
INSERT INTO klient VALUES('Kaja','Olszewska');
INSERT INTO klient VALUES('Jolanta','Woźniak');
INSERT INTO klient VALUES('Augustyn','Jaworski');
INSERT INTO klient VALUES('Wioletta','Majewska');
INSERT INTO klient VALUES('Wielisław','Sawicki');
INSERT INTO klient VALUES('Rościsława','Sobczak');

INSERT INTO oferta_dealera VALUES('53583868545080825','CarCom');
INSERT INTO oferta_dealera VALUES('71206667173749805','FastSale');
INSERT INTO oferta_dealera VALUES('41762623850489997','InterCar');
INSERT INTO oferta_dealera VALUES('28597512667119666','CheapWheels');
INSERT INTO oferta_dealera VALUES('50771862141656972','ValueVehicles');
INSERT INTO oferta_dealera VALUES('50354729546078273','FastAndCheap');
INSERT INTO oferta_dealera VALUES('10105484846689802','AndMar');
INSERT INTO oferta_dealera VALUES('27057797557734859','BullitCars');
INSERT INTO oferta_dealera VALUES('86642245931626140','DriveForCheap');
INSERT INTO oferta_dealera VALUES('95191600989517207','CarsForCents');


INSERT INTO katalog_dealera VALUES(1,'CarCom');
INSERT INTO katalog_dealera VALUES(3,'FastSale');
INSERT INTO katalog_dealera VALUES(7,'InterCar');
INSERT INTO katalog_dealera VALUES(11,'CheapWheels');
INSERT INTO katalog_dealera VALUES(15,'ValueVehicles');
INSERT INTO katalog_dealera VALUES(19,'FastAndCheap');
INSERT INTO katalog_dealera VALUES(6,'AndMar');
INSERT INTO katalog_dealera VALUES(2,'BullitCars');
INSERT INTO katalog_dealera VALUES(10,'DriveForCheap');
INSERT INTO katalog_dealera VALUES(8,'CarsForCents');

INSERT INTO sprzedaz VALUES(12200,'2017-10-23',1,'InterCar','53583868545080825');
INSERT INTO sprzedaz VALUES(6320,'2019-02-11',3,'CarCom','41762623850489997');
INSERT INTO sprzedaz VALUES(15320,'2016-11-22',2,'FastSale','71206667173749805');
INSERT INTO sprzedaz VALUES(23180,'2018-09-02',4,'FastAndCheap','28597512667119666');
INSERT INTO sprzedaz VALUES(32100,'2016-02-18',6,'BullitCars','95191600989517207');
INSERT INTO sprzedaz VALUES(17500,'2017-03-11',8,'AndMar','86642245931626140');
INSERT INTO sprzedaz VALUES(21200,'2018-07-06',5,'DriveForCheap','10105484846689802');
INSERT INTO sprzedaz VALUES(37300,'2016-07-20',7,'CarsForCents','50771862141656972');
INSERT INTO sprzedaz VALUES(28100,'2017-05-01',10,'CheapWheels','50354729546078273');
INSERT INTO sprzedaz VALUES(8310,'2018-04-10',9,'ValueVehicles','27057797557734859');

GO 

CREATE FUNCTION ufn_dealermodelu(@nazwa VARCHAR(max))
RETURNS TABLE
AS
	RETURN SELECT D1.nazwa,
					D1.adres
	FROM dealer D1
		JOIN katalog_dealera K1
			ON K1.katalog_dealer = D1.nazwa
				JOIN model M1
					ON M1.identyfikator = K1.katalog_modele
	WHERE M1.nazwa =  @nazwa
GO

CREATE PROCEDURE usp_sprzedaz
    @vin VARCHAR(17),
    @cena INT,
    @data DATE,
    @klient INT,
    @dealer VARCHAR(30)



    AS
    BEGIN
        DELETE FROM oferta_dealera WHERE vin_samochodu = @vin;
        INSERT INTO sprzedaz VALUES(@cena,@data,@klient,@dealer,@vin);
    END;
    GO
CREATE PROCEDURE usp_usun_z_katalogu
    @km INT,
    @kd VARCHAR(30)

    AS
    BEGIN
        DELETE FROM katalog_dealera WHERE katalog_modele = @km AND  katalog_dealer = @kd;
    END;
    GO

CREATE PROCEDURE usp_zmien_przebieg
    @vin VARCHAR(17),
    @przebieg INT

    AS
    BEGIN
        UPDATE samochod
        SET przebieg = @przebieg
        WHERE vin = @vin
    END; 
    GO

CREATE PROCEDURE usp_srednia_cena
	@result VARCHAR(max) OUTPUT
	AS
	BEGIN
		SELECT @result = AVG(cena) 
		FROM sprzedaz
	PRINT 'Średnia cena sprzedanych do tej pory samochodów wynosi ' + @result;
	END;
	GO

CREATE VIEW sprzedaze(klient_imie,klient_nazwisko,dealer,marka,model,cena,data)
	AS
	(
		SELECT K1.imie AS 'klient_imie',
			   K1.nazwisko AS 'klient_nazwisko',
			   S1.nazwa_dealera AS 'dealer',
			   Z1.nazwa AS 'marka',
			   A1.nazwa AS 'model',
			   S1.cena,
			   S1.data
			   FROM sprzedaz S1
					JOIN klient K1
						ON S1.id_klienta = K1.identyfikator
						JOIN samochod T1
							ON S1.id_samochodu = T1.vin
								JOIN model A1
									ON A1.identyfikator = T1.model_samochodu
									JOIN marka Z1
										ON Z1.nazwa = A1.marka_modelu);
GO


----Przykładowe wywołania----
SELECT * FROM sprzedaze
GO

DECLARE @result INT

EXEC usp_srednia_cena
	@result 

GO

SELECT * FROM samochod

EXEC usp_zmien_przebieg
	'53583868545080825',
	300000

SELECT * FROM samochod

GO

SELECT * FROM katalog_dealera

EXEC usp_usun_z_katalogu
	1,
	'CarCom'
SELECT * FROM katalog_dealera

GO

SELECT * FROM oferta_dealera

EXEC usp_sprzedaz
	'71206667173749805',
	12000,
	'2016-11-21',
	4,
	'FastSale'


SELECT * FROM oferta_dealera

GO

SELECT * FROM ufn_dealermodelu('Yaris')

GO

DECLARE @result INT

SELECT dbo.ufn_datecompare('1700-01-01','Alfa Romeo')

--Powyższa funkcja służy do porównywania daty produkcji samochodu z datą powstania marki, używana jest w założeniach zawartości tabeli 'samochod'

INSERT INTO samochod VALUES('53583868545080821','Polska',398715,'manualna','2005',7,1);