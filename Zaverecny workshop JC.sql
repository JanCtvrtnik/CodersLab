/*Struktura databáze
Struktura financialdatabáze
Seznamte se se schématem databáze a odpovězte na následující otázky:
Jaké jsou primární klíče v jednotlivých tabulkách?
Jaké vztahy mají jednotlivé dvojice tabulek?*/

/*Jenotlive tabulky a jejich primarni klice*/

Tabulka      Primarni klic
   ^             ^
account    - account_id,
card       - card_id,
client     - client_id,
disp       - disp_id,
district   - district,
loan       - loan_id,
order      - order_id,
trans      - trans_id.*/




/*Historie poskytnutých úvěrů
Napište dotaz, který připraví souhrn poskytnutých úvěrů v následujících dimenzích:

rok, čtvrtletí, měsíc,
rok, čtvrtletí,
rok,
celkový.*/

-- Souhrn poskytnutých úvěrů podle časových dimenzí

-- Rok + čtvrtletí + měsíc
SELECT
    YEAR(date) AS rok,
    QUARTER(date) AS ctvrtleti,
    MONTH(date) AS mesic,
    SUM(amount) AS celkem_uveru
FROM loan
GROUP BY YEAR(date), QUARTER(date), MONTH(date)
order by rok, ctvrtleti, mesic;





/*Jako výsledek shrnutí zobrazte následující informace:

celková výše úvěrů,
průměrná výše úvěru,
celkový počet poskytnutých půjček.*/

select
    sum(amount) as celkova_vyse_uveru,
    avg(amount) as prumerna_vyse_uveru,
    count(loan_id) as celokovy_pocet_poskytnutych_uveru
from loan;

/*Stav úvěru
Na webu databáze můžeme najít informaci, že v databázi je celkem 682 udělených úvěrů, z nichž 606 bylo splaceno a 76 ne.

Předpokládejme, že nemáme informace o tom, který stav odpovídá splacené půjčce a který ne. V této situaci musíme tuto informaci odvodit z dat.

Chcete-li to provést, napište dotaz, který vám pomůže odpovědět na otázku, které stavy představují splacené půjčky a které nesplacené půjčky.*/

select count(*)
from loan

SELECT
    status,
    count(status)
FROM loan
GROUP BY status
ORDER BY status;


/*Analýza účtů

Napište dotaz, který seřadí účty podle následujících kritérií:

počet poskytnutých půjček (klesající),
objem poskytnutých úvěrů (klesající),
průměrná výše úvěru,

Zohledňují se pouze plně splacené půjčky.*/

WITH pujcky_splacene AS (
  SELECT
    account_id,
    COUNT(*) AS pocet_pujcek,
    SUM(amount) AS celkova_castka,
    round(AVG(amount)) AS prumerna_castka
  FROM loan
  WHERE status IN ('A', 'C')
  GROUP BY account_id
)

SELECT *,
  RANK() OVER (
    ORDER BY pocet_pujcek DESC, celkova_castka DESC, prumerna_castka DESC
  ) AS poradi
FROM pujcky_splacene;

/*Plně splacené půjčky

Zjistěte zůstatek splacených úvěrů dělený podle pohlaví klienta.

Dále použijte metodu dle vlastního výběru k ověření, zda je dotaz správný.*/

select
    gender,
    FORMAT(SUM(amount), 0) AS celkova_splacena_castka
from loan
join  account on loan.account_id = account.account_id
join  disp on account.account_id = disp.account_id
join  client on disp.client_id = client.client_id
where status in ('A', 'C')
    AND type = 'OWNER'
group by gender

-- ✅ Ověření správnosti – kontrolní dotaz (celkem):
-- → Součet výše uvedeného dotazu musí odpovídat součtu částek z předchozího dotazu rozděleného podle gender.
SELECT
  format(sum(amount),0) AS celkem_splaceno
FROM loan
WHERE status IN ('A', 'C');

/*Analýza klienta - 1. část
Upravte dotazy z cvičení o splacených úvěrech a odpovězte na následující otázky:*/
SELECT
  c.gender,
  ROUND(AVG(TIMESTAMPDIFF(YEAR, c.birth_date, CURRENT_DATE))) AS prumerny_vek
FROM client c
JOIN disp d ON c.client_id = d.client_id
JOIN account a ON d.account_id = a.account_id
JOIN loan l ON a.account_id = l.account_id
WHERE l.status IN ('A', 'C')
  AND d.type = 'OWNER'
GROUP BY c.gender;

/*Kdo má více splacených půjček - ženy nebo muži?
Jaký je průměrný věk dlužníka dělený podle pohlaví?*/
INSERT INTO MY_TABLE(gender, celkova_splacena_castka, prumerny_vek) VALUES ('M', '43,256,388', 67);
INSERT INTO MY_TABLE(gender, celkova_splacena_castka, prumerny_vek) VALUES ('F', '44,425,200', 65);

/*Analýza klienta - 2. část
Proveďte analýzy, které odpoví na otázky:

která oblast má nejvíce klientů,*/
SELECT
  a.district_id,
  COUNT(DISTINCT d.client_id) AS pocet_klientu
FROM disp d
JOIN account a ON d.account_id = a.account_id
WHERE d.type = 'OWNER'
GROUP BY a.district_id
ORDER BY pocet_klientu DESC
LIMIT 1;

/*ve které oblasti byl splacen nejvyšší počet půjček*/
SELECT
  dis.A2 AS oblast,
  COUNT(*) AS pocet_splacenych_pujcek
FROM loan l
JOIN account a ON l.account_id = a.account_id
JOIN disp d ON a.account_id = d.account_id
JOIN district dis ON a.district_id = dis.district_id
WHERE l.status IN ('A', 'C') AND d.type = 'OWNER'
GROUP BY dis.A2
ORDER BY pocet_splacenych_pujcek DESC
LIMIT 1;


-- ve které oblasti byla vyplacena nejvyšší částka půjček.
-- Jako klienty vyberte pouze vlastníky účtů.*/
SELECT
  dis.A2 AS oblast,
  SUM(l.amount) AS celkova_castka_pujcek
FROM loan l
JOIN account a ON l.account_id = a.account_id
JOIN disp d ON a.account_id = d.account_id
JOIN district dis ON a.district_id = dis.district_id
WHERE l.status IN ('A', 'C') AND d.type = 'OWNER'
GROUP BY dis.A2
ORDER BY celkova_castka_pujcek DESC
LIMIT 1;

/*Analýza klienta - 3. část
Použijte dotaz vytvořený v předchozím úkolu a upravte ho tak, aby určoval procentuální podíl každého okresu na celkovém objemu poskytnutých úvěrů.*/

SELECT
  a.district_id,
  SUM(l.amount) AS castka_zakaznika,                -- celková částka
  ROUND(AVG(l.amount)) AS vyse_pujcek,              -- průměrná výše půjčky
  COUNT(*) AS pocet_pujcek,                         -- počet půjček
  ROUND(SUM(l.amount) / (
    SELECT SUM(amount)
    FROM loan
    WHERE status IN ('A', 'C')
  ), 4) AS podil_amount                             -- procentuální podíl
FROM loan l
JOIN account a ON l.account_id = a.account_id
JOIN disp d ON a.account_id = d.account_id
WHERE l.status IN ('A', 'C')
  AND d.type = 'OWNER'
GROUP BY a.district_id
ORDER BY podil_amount DESC;

-- Výběr - 1. část
-- Výběr klienta
-- Zkontrolujte v databázi klienty, kteří splňují následující výsledky:

-- zůstatek na jejich účtu je vyšší než 1000,
-- mají více než 5 půjček,
-- narodili se po roce 1990.
-- A předpokládáme, že zůstatek na účtu je loan amount- payments.*/

SELECT
  c.client_id,
  COUNT(l.loan_id) AS pocet_pujcek,
  SUM(l.amount) AS celkem_pujcek,
  IFNULL(SUM(amount), 0) AS celkem_splaceno,
  (SUM(l.amount) - IFNULL(SUM(amount), 0)) AS zustatek
FROM client c
JOIN disp d ON c.client_id = d.client_id
JOIN account a ON d.account_id = a.account_id
JOIN loan l ON a.account_id = l.account_id
WHERE d.type = 'OWNER'
  AND YEAR(c.birth_date) > 1990
GROUP BY c.client_id
HAVING
  zustatek > 1000
  AND pocet_pujcek > 5
ORDER BY zustatek DESC;

/*Výběr, část 2
Z předchozího cvičení pravděpodobně již víte, že neexistují žádní zákazníci, kteří by splňovali požadavky.
Proveďte analýzu, abyste zjistili, která podmínka způsobila prázdné výsledky.*/

SELECT
    c.client_id,

    sum(amount - payments) as client_balance,
    count(loan_id) as loans_amount
FROM loan as l
         INNER JOIN
     account a using (account_id)
         INNER JOIN
     disp as d using (account_id)
         INNER JOIN
     client as c using (client_id)
WHERE True
  AND l.status IN ('A', 'C')
  AND d.type = 'OWNER'
--  AND EXTRACT(YEAR FROM c.birth_date) > 1990
GROUP BY c.client_id
HAVING
    sum(amount - payments) > 1000
--    and count(loan_id) > 5
ORDER BY loans_amount DESC;

/*Karty s vypršením platnosti
Napište proceduru pro aktualizaci vytvořené tabulky (můžete ji nazvat např. cards_at_expiration),
která obsahuje následující sloupce:

ID_klienta,
ID_karty,
datum_expirace - předpokládá se, že karta může být aktivní 3 roky od data vydání,
client_adresa ( A3stejný sloupec).
Poznámka: Stůl cardobsahuje karty, které byly vydány do konce roku 1998.

Určení data platnosti karty:

Předpokládejme, že máme kartu vydanou dne 2020-01-01,
jejíž datum platnosti je podle podmínek uplatnění 2023-01-01.
Protože chceme nové karty odeslat týden před datem platnosti,
stačí zkontrolovat stav 2023-01-01 - 7 days = 2022-12-25 <= DATE <= 2023-01-01.
 */

--  Krok 1: Vytvoření tabulky cards_at_expiration
CREATE TABLE IF NOT EXISTS cards_at_expiration (
  client_id INT,
  card_id INT,
  expiration_date DATE,
  client_address VARCHAR(255)
);

-- Krok 2: Vytvoření procedury pro aktualizaci tabulky

DELIMITER //

CREATE PROCEDURE update_cards_at_expiration()
BEGIN
  -- Nejprve vymažeme starý obsah (pokud chceme přegenerovat)
  DELETE FROM cards_at_expiration;

  -- Vložíme nové záznamy
  INSERT INTO cards_at_expiration (client_id, card_id, expiration_date, client_address)
  SELECT
    c.client_id,
    ca.card_id,
    DATE_ADD(ca.issued, INTERVAL 3 YEAR) AS expiration_date,
    d.A3 AS client_address
  FROM card ca
  JOIN disp d2 ON ca.disp_id = d2.disp_id
  JOIN client c ON d2.client_id = c.client_id
  JOIN account a ON d2.account_id = a.account_id
  JOIN district d ON a.district_id = d.district_id
  WHERE DATE_ADD(ca.issued, INTERVAL 3 YEAR) BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);
END //

DELIMITER ;

-- Krok 3: Spuštění procedury
CALL update_cards_at_expiration();

