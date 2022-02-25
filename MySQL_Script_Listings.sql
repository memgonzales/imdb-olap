-- Listing 9. Movie Title Standardization --
UPDATE movies SET `name` =
RTRIM(REVERSE(SUBSTRING(REVERSE(`name`),
LOCATE(" ",REVERSE(`name`)))))
WHERE `name` IN (
   SELECT `name`
   FROM (
      SELECT `name`
      FROM movies
	WHERE name LIKE "%(%)"
   ) AS tmp
);

UPDATE movies SET `name` =
RTRIM(REVERSE(SUBSTRING(REVERSE(`name`),
LOCATE(" ",REVERSE(`name`)))))
WHERE `name` IN (
   SELECT `name`
   FROM (
      SELECT `name`
      FROM movies
	WHERE name LIKE "%, The"
   ) AS tmp
);

UPDATE movies SET `name` = CONCAT("The ", 
   `name`)
WHERE `name` IN (
   SELECT `name`
   FROM (
        SELECT `name`
        FROM movies
        WHERE name LIKE "%,"
   ) AS tmp
);

UPDATE movies SET `name` = SUBSTRING(`name`,     
    1, CHAR_LENGTH(`name`) - 1)
WHERE `name` IN (
    SELECT `name`
   FROM (
      SELECT `name`
      FROM movies
      WHERE name LIKE "%,"
   ) AS tmp
);

-- Listing 10. Temporary Mapping Table for Movie IDs --
CREATE TABLE ijs2supplementary AS (
   SELECT DISTINCT movie_id, imdb_title_id
   FROM movies 
   LEFT JOIN imdb_movies 
      ON LOWER(movies.name) = 
         LOWER(imdb_movies.original_title)
      AND movies.year =  
         YEAR(imdb_movies.date_published)
);

-- Listing 11. Extraction Query for movies Table --
SELECT DISTINCT movie_id, `name`, `year`,  
   `rank`, title as other_name, duration,   
   `language`, production_company, 
   `description`, votes, budget, 
   usa_gross_income, 
   worlwide_gross_income AS 
   worldwide_gross_income, metascore, 
   reviews_from_users, reviews_from_critics 
FROM movies 
LEFT JOIN imdb_movies 
   ON LOWER(movies.name) = 
      LOWER(imdb_movies.original_title)
   AND movies.year =  
      YEAR(imdb_movies.date_published);

-- Listing 12. Extraction Query for directors Table --
SELECT director_id, first_name, last_name, 
   rate, gross
FROM directors LEFT JOIN imdb_full_directors d
ON directors.first_name = d.first_name
AND directors.last_name = d.last_name;

-- Listing 13. Extraction Query for actors Table --
SELECT actor_id, first_name, last_name, gender
FROM actors;

-- Listing 14. Extraction Query for roles Table --
SELECT actor_id, movie_id
FROM roles;

-- Listing 15. Extraction Query for ratings Table --
SELECT total_votes AS 
   total_num_vote, votes_10, votes_9, votes_8, 
   votes_7, votes_6, votes_5, votes_4, 
   votes_3, votes_2, votes_1, 
   allgenders_0age_avg_vote, 
   allgenders_0age_votes, 
   allgenders_18age_avg_vote, 
   allgenders_18age_votes, 
   allgenders_30age_avg_vote, 
   allgenders_30age_votes, 
   allgenders_45age_avg_vote, 
   allgenders_45age_votes, 
   males_allages_avg_vote, 
   males_allages_votes, males_0age_avg_vote, 
   males_0age_votes, males_18age_avg_vote, 
   males_18age_votes, males_30age_avg_vote, 
   males_30age_votes, males_45age_avg_vote, 
   males_45age_votes, 
   females_allages_avg_vote, 
   females_allages_votes, 
   females_0age_avg_vote, females_0age_votes, 
   females_18age_avg_vote, 
   females_18age_votes, 
   females_30age_avg_vote, 
   females_30age_votes, 
   females_45age_avg_vote, 
   females_45age_votes, top1000_voters_rating, 
   top1000_voters_votes, us_voters_rating, 
   us_voters_votes, non_us_voters_rating, 
   non_us_voters_votes
FROM imdb_ratings;

-- Listing 16. Extraction Query for genres Table --
SELECT DISTINCT genre
FROM movies_genres;

-- Listing 17. Extraction Query for countries Table --
SELECT DISTINCT country
FROM imdb_movies;

-- Listing 18. Extraction Query for the Fact Table --
SELECT movie_id, country_id, genre_id, 
   director_id, actor_id, role_id, rating_id
FROM movies 
LEFT JOIN (movies_directors
JOIN directors
   ON directors.director_id =
   movies_directors.director_id)
ON movies.movie_id = 
      movies_directors.movie_id 
LEFT JOIN (movies_actors
JOIN actors
   ON actors.actor_id = 
      movies_actors.actor_id)
ON movies.movie_id = 
   movies_actors.movie_id
LEFT JOIN genres
   ON movies.movie_id = movies_genres.genre
LEFT JOIN roles
   ON movies.movie_id = roles.movie_id
   AND actors.actor_id = roles.actor_id
LEFT JOIN (ijs2supplementary
JOIN imdb_movies
   ON ijs2supplementary.imdb_title_id = 
      imdb_movies.imdb_title_id
JOIN imdb_ratings
   ON ijs2supplementary.imdb_title_id =
      imdb_ratings.imdb_title_id)
ON movies.movie_id = 
   ijs2supplementary.imdb_title_id;


-- Listing 19. Script for Standardizing prodcompanies Names --
ALTER TABLE movies
ADD production_company_clean VARCHAR(45);

UPDATE movies SET production_company_clean =  
   (SELECT SUBSTRING_INDEX(production_company, 
        '- (', 1)
    FROM (
       SELECT 
       SUBSTRING_INDEX(production_company, 
          ' [', 1) 
       FROM movies));

-- Listing 20. SQL Statement for Query 5.1 (Normalized) --
SELECT CONCAT(FLOOR(m.year/10) * 10, 's') AS 
   decade_released, m.year, g.genre, 
   (SUM(r.votes_10) + SUM(r.votes_9) + 
   SUM(r.votes_8) + SUM(r.votes_7) + 
   SUM(r.votes_6) + SUM(r.votes_5) + 
   SUM(r.votes_4) + SUM(r.votes_3) +   
   SUM(r.votes_2) + SUM(r.votes_1)) AS 
   total_num_votes,
   SUM(r.votes_10) AS votes_10, SUM(r.votes_9) 
   AS votes_9, SUM(r.votes_8) AS votes_8, 
   SUM(r.votes_7) AS votes_7, SUM(r.votes_6) AS 
   votes_6, SUM(r.votes_5) AS votes_5, 	   
   SUM(r.votes_4) AS votes_4, SUM(r.votes_3) AS 
   votes_3, SUM(r.votes_2) AS votes_2, 
   SUM(r.votes_1) AS votes_1 
FROM movies m
JOIN genres g ON g.movie_id = m.movie_id
JOIN ijs2supplementary i ON i.movie_id = 
   m.movie_id
JOIN imdb_ratings r ON r.imdb_title_id = 
   i.imdb_title_id
GROUP BY decade_released, m.year, g.genre 
   WITH ROLLUP
ORDER BY decade_released, m.year, g.genre;

-- Listing 21. SQL Statement for Query 5.1 (Denormalized) --
SELECT CONCAT(FLOOR(m.year/10) * 10, 's') AS  
   decade_released, m.year, g.genre,  
   SUM(r.total_num_votes) AS total_votes,
   SUM(r.votes_10) AS votes_10, SUM(r.votes_9) 
   AS votes_9, SUM(r.votes_8) AS votes_8, 
   SUM(r.votes_7) AS votes_7, SUM(r.votes_6) AS 
   votes_6, SUM(r.votes_5) AS votes_5, 
   SUM(r.votes_4) AS votes_4, SUM(r.votes_3) AS 
   votes_3, SUM(r.votes_2) AS votes_2, 
   SUM(r.votes_1) AS votes_1
FROM fact_table f
JOIN movies m ON m.movie_id = f.movie_id
JOIN ratings r ON r.rating_id = f.rating_id
JOIN genres g ON g.genre_id = f.genre_id
GROUP BY decade_released, m.year, g.genre 
   WITH ROLLUP
ORDER BY decade_released, m.year, g.genre;

-- Listing 22. SQL Statement for Query 5.2 (Normalized) --
SELECT CONCAT(FLOOR(m.year/10) * 10, 's') AS 
   decade_released, m.year, g.genre, 	     
   (SUM(r.votes_10) + SUM(r.votes_9) +   
   SUM(r.votes_8) + 
   SUM(r.votes_7) + SUM(r.votes_6) + 
   SUM(r.votes_5) + 
   SUM(r.votes_4) + SUM(r.votes_3) + 
   SUM(r.votes_2) + 
   SUM(r.votes_1)) AS total_num_votes,
   SUM(r.males_allages_votes) AS votes_male, 
   SUM(r.females_allages_votes) AS votes_female
FROM movies m
JOIN genres g ON g.movie_id = m.movie_id
JOIN ijs2supplementary i ON i.movie_id = 
   m.movie_id
JOIN imdb_ratings r ON r.imdb_title_id = 
   i.imdb_title_id
GROUP BY decade_released, m.year, g.genre
   WITH ROLLUP
ORDER BY decade_released, m.year, g.genre;

-- Listing 23.  SQL Statement for Query 5.2 (Denormalized) --
SELECT CONCAT(FLOOR(m.year/10) * 10, 's') AS  
   decade_released, m.year, g.genre, 
   SUM(r.total_num_votes) AS total_votes, 
   SUM(r.males_allages_votes) AS votes_male, 
   SUM(r.females_allages_votes) AS votes_female
FROM fact_table f
JOIN movies m ON m.movie_id = f.movie_id
JOIN genres g ON g.genre_id = f.genre_id
JOIN ratings r ON r.rating_id = f.rating_id
GROUP BY decade_released, m.year, g.genre
   WITH ROLLUP
ORDER BY decade_released, m.year, g.genre;

-- Listing 24. SQL Statement for Query 5.3 (Normalized) --
SELECT name, Num_roles
FROM (
   SELECT a.name, COUNT(m.movie_id) 
      AS Num_roles,
      RANK() OVER 
         (PARTITION BY g.genre
          ORDER BY COUNT(m.movie_id) DESC) AS 
          Num_roles_rank
   FROM movies m 
   JOIN genres g ON g.movie_id = m.movie_id
   JOIN roles i ON i.movie_id = m.movie_id
   JOIN actors a ON a.actor_id = i.actor_id
   WHERE g.genre = "Action"
   GROUP BY g.genre, a.name
) AS Role_rank
WHERE Num_roles_rank <= 15;

-- Listing 25. SQL Statement for Query 5.3 (Denormalized) --
SELECT name, Num_roles
FROM (
   SELECT CONCAT(a.last_name, ", ",
      a.first_name) AS name,  COUNT(m.movie_id) 
      AS Num_roles,
      RANK() OVER 
         (PARTITION BY g.genre
          ORDER BY COUNT(m.movie_id) DESC) AS 
          Num_roles_rank
    FROM fact_table f
    JOIN genres g ON f.genre_id = g.genre_id
    JOIN actors a ON f.actor_id = a.actor_id
    JOIN movies m ON f.movie_id = m.movie_id
    WHERE g.genre = "Action"
    GROUP BY g.genre, a.last_name, a.first_name
) AS Role_rank
WHERE Num_roles_rank <= 15;

-- Listing 26. SQL Statement for Query 5.3 (Optimized) --
 SELECT CONCAT(a.last_name, ", ", a.first_name)     
    AS name, COUNT(m.movie_id) AS Num_roles
 FROM
    (SELECT *
     FROM fact_table 
     WHERE genre_id = (
        SELECT genre_id 
        FROM genres 
        WHERE genre = "Action")) 
     AS f
 JOIN actors a ON f.actor_id = a.actor_id
 JOIN movies m ON f.movie_id = m.movie_id  
 GROUP BY a.last_name, a.first_name
 ORDER BY Num_roles DESC
 LIMIT 15;

-- Listing 27. SQL Statement for Query 5.4 (Normalized) --
SELECT *
FROM (
   SELECT c.country, g.genre, COUNT(m.movie_id) 
      AS Num_movies,
      RANK() OVER 
         (PARTITION BY c.country
	  ORDER BY COUNT(m.movie_id) DESC) AS
            Num_movies_rank
   FROM movies m
   JOIN countries c ON c.movie_id = m.movie_id
   JOIN genres g ON g.movie_id = m.movie_id
   WHERE c.country  != ""
   GROUP BY c.country, g.genre
) AS Movies_rank
WHERE Num_movies_rank <= 10;

-- Listing 28. SQL Statement for Query 5.4 (Denormalized) --
SELECT *
FROM (
   SELECT c.country, g.genre, COUNT(m.movie_id) 
      AS Num_movies,
   RANK() OVER 
      (PARTITION BY c.country
       ORDER BY COUNT(m.movie_id) DESC) AS 
       Num_movies_rank
   FROM fact_table f
   JOIN countries c ON c.country_id = 
      f.country_id
   JOIN genres g ON g.genre_id = f.genre_id
   JOIN movies m ON m.movie_id = f.movie_id
   WHERE c.country  != ""
   GROUP BY c.country, g.genre
) AS Movies_rank
WHERE Num_movies_rank <= 10;

-- Listing 29. SQL Statement for Query 5.5 (Normalized) --
SELECT CONCAT(FLOOR(year/10) * 10, 's') AS 
   decade_released, m.year, COUNT(m.movie_id) AS 
   num_movies
FROM fact_table f
JOIN genres g ON g.genre_id = f.genre_id
JOIN movies m ON m.movie_id = f.movie_id
JOIN countries c ON c.country_id = f.country_id
WHERE c.country = "USA"
   AND g.genre = "Horror"
GROUP BY decade_released, m.year WITH ROLLUP;

-- Listing 30. SQL Statement for Query 5.5 (Denormalized) --
SELECT CONCAT(FLOOR(year/10) * 10, 's') AS 
   decade_released, m.year, COUNT(m.movie_id) AS   
   num_movies
FROM fact_table f
JOIN genres g ON g.genre_id = f.genre_id
JOIN movies m ON m.movie_id = f.movie_id
JOIN countries c ON c.country_id = f.country_id
WHERE c.country = "USA"
   AND g.genre = "Horror"
GROUP BY decade_released, m.year WITH ROLLUP;

-- Listing 31. SQL Statement for Query 5.5 (Optimized) --
 SELECT CONCAT(FLOOR(year/10) * 10, 's') AS 
   decade_released, m.year, COUNT(m.movie_id) AS   
   num_movies
 FROM (
    SELECT *
    FROM fact_table
    WHERE country_id = (
        SELECT country_id
        FROM countries
        WHERE country = "USA"
    )
    AND genre_id = (
		SELECT genre_id
        FROM genres
        WHERE genre = "Horror"
    )) AS f
 JOIN movies m ON m.movie_id = f.movie_id
 GROUP BY decade_released, m.year WITH ROLLUP;

-- Listing 32. SQL Statement for Query 5.6 (Normalized) --
SELECT production_company, COUNT(imdb_title_id) 
   AS num_movies
FROM (	
   SELECT i.production_company, i.imdb_title_id
   FROM imdb_movies i
   WHERE i.imdb_title_id IN (	
      SELECT r.imdb_title_id
      FROM imdb_ratings r
      WHERE r.mean_vote > (	
         SELECT AVG(r.mean_vote)
         FROM imdb_ratings r
      )
   ) 
   AND imdb_title_id IN (
      SELECT i.imdb_title_id
      FROM imdb_movies i
      WHERE i.votes > (
	  SELECT AVG(i.votes)
          FROM imdb_movies i
      )
   )
) AS selected_movies
GROUP BY production_company
HAVING num_movies > 10
ORDER BY num_movies DESC;

-- Listing 33. SQL Statement for Query 5.6 (Denormalized) --
SELECT production_company, COUNT(movie_id) AS 
   num_movies    
FROM (   
   SELECT m.movie_id, m.production_company, 
       total_num_votes AS total
   FROM movies m
   JOIN fact_table ft 
      ON ft.movie_id = m.movie_id
   JOIN ratings ra 
      ON ra.rating_id = ft.rating_id
   WHERE m.production_company IS NOT NULL
   AND m.rank > (	
      SELECT AVG(m.rank)
      FROM movies m
   )
   GROUP BY m.movie_id
   HAVING total > (
      SELECT AVG(total_num_votes)
      FROM (            
         SELECT  name, total_num_votes
         FROM fact_table f
         JOIN movies m 
            ON m.movie_id = f.movie_id
         JOIN ratings r
            ON r.rating_id = f.rating_id
         JOIN genres g 
            ON g.genre_id = f.genre_id
	) as total_votes)
   ) AS selected_movies
GROUP BY production_company
HAVING num_movies > 10
ORDER BY num_movies DESC;

-- Listing 34. SQL Statement for Query 5.7 (Normalized) --
SELECT name, title, `rank`
FROM (
   SELECT m.title, topdir.name, topdir.gross, 
      r.rank, ROW_NUMBER() OVER(PARTITION BY      
      topdir.name ORDER BY `rank` DESC) AS 
      director_movie_rank
   FROM (
      SELECT d.directorid, d.name, d.gross
      FROM directors d
      ORDER BY d.gross DESC
      LIMIT 6
   ) as topdir
   JOIN movies m 
   JOIN ratings r ON r.movieid = m.movieid 
   JOIN movies2directors md ON md.movieid = 
      m.movieid AND md.directorid = 
      topdir.directorid
   ORDER BY topdir.gross DESC, r.rank DESC
) AS topdirmovies
WHERE director_movie_rank <= 15;

-- Listing 35. SQL Statement for Query 5.7 (Denormalized) --
SELECT full_name, gross, name, `rank`
FROM (	
   SELECT full_name, m.name, gross, m.rank, 
      ROW_NUMBER() OVER
      (PARTITION BY td.director_id ORDER BY 
          `rank` DESC) AS Director_movie_rank
   FROM (	
      SELECT d.director_id,  
         CONCAT(CONCAT(d.last_name, ", "), 
         d.first_name) AS full_name, d.gross
      FROM directors d
      ORDER BY d.gross DESC
      LIMIT 6
   ) as td
   JOIN fact_table f ON td.director_id = 
      f.director_id
   JOIN movies m ON m.movie_id = f.movie_id
   WHERE `rank` IS NOT NULL
   GROUP BY m.movie_id
   ORDER BY gross DESC, m.rank DESC
) AS top_director_movies
WHERE Director_movie_rank <= 15;

-- Listing 36. Metadata Validation --
SELECT TABLE_NAME, COLUMN_NAME, 
   ORDINAL_POSITION, IS_NULLABLE, COLUMN_TYPE, 
   COLLATION_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'imdb_ijs';

-- Listing 37. Content Validation --
CHECKSUM TABLE imdb_ijs.actors; 

-- Listing 38. Movie Title Wrangling Validation (Comma) --
SELECT COUNT(*) FROM imdb_star.movies
WHERE `name` LIKE "%,";

-- Listing 39. Movie Title Wrangling Validation (Article) --
SELECT COUNT(*) FROM imdb_star.movies
WHERE `name` LIKE "%, The";

-- Listing 40. Genre Wrangling Validation --
SELECT COUNT(*) FROM imdb_star.genres
WHERE genre LIKE "%,%";

-- Listing 41. Production Company Wrangling Validation (Brackets) --
SELECT COUNT(*) FROM imdb_star.genres
WHERE genre LIKE "%[%]";

-- Listing 42. Production Company Wrangling Validation (Parentheses) --
SELECT COUNT(*) FROM imdb_star.movies
WHERE production_company LIKE "%- (%)";