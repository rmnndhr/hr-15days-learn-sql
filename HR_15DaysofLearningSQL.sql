/*
Write a query to print total number of unique hackers who made at least 1
submission each day (starting on the first day of the contest), and find the 
hacker_id and name of the hacker who made maximum number of submissions 
each day. If more than one such hacker has a maximum number of submissions, 
print the lowest hacker_id. The query should print this information for each day of 
the contest, sorted by the date.
Assume that the end date of the contest was March 06, 2016.
*/

-- 
WITH t1 AS (
	SELECT s.submission_date, s.hacker_id, h.name, COUNT(*) AS daily_subs
	FROM public.submissions AS s
	INNER JOIN public.hackers AS h
	ON s.hacker_id = h.hacker_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 2
),
mar1 AS (
	SELECT submission_date, hacker_id
	FROM t1
	WHERE submission_date = '2016-03-01'
	GROUP BY 1, 2
	ORDER BY 1
),
mar2 AS (
	SELECT t1.submission_date, t1.hacker_id
	FROM t1
	INNER JOIN mar1
	ON t1.hacker_id = mar1.hacker_id AND t1.submission_date = '2016-03-02'	
),
mar3 AS (
	SELECT t1.submission_date, t1.hacker_id
	FROM t1
	INNER JOIN mar2
	ON t1.hacker_id = mar2.hacker_id AND t1.submission_date = '2016-03-03'
),
mar4 AS (
	SELECT t1.submission_date, t1.hacker_id
	FROM t1
	INNER JOIN mar3
	ON t1.hacker_id = mar3.hacker_id AND t1.submission_date = '2016-03-04'
),
mar5 AS (
	SELECT t1.submission_date, t1.hacker_id
	FROM t1
	INNER JOIN mar4
	ON t1.hacker_id = mar4.hacker_id AND t1.submission_date = '2016-03-05'
),
mar6 AS (
	SELECT t1.submission_date, t1.hacker_id
	FROM t1
	INNER JOIN mar5
	ON t1.hacker_id = mar5.hacker_id AND t1.submission_date = '2016-03-06'
),
t2 AS (
	SELECT * 
	FROM mar1 
	UNION SELECT * 
	FROM mar2
	UNION SELECT * 
	FROM mar3
	UNION SELECT * 
	FROM mar4
	UNION SELECT * 
	FROM mar5
	UNION SELECT * 
	FROM mar6
	ORDER BY 1
),
t3 AS (
	SELECT submission_date, hacker_id, name, daily_subs,
		NTILE(500) OVER (PARTITION BY submission_date ORDER BY daily_subs DESC, hacker_id) AS percentile
	FROM t1
)
SELECT t3.submission_date, COUNT(*) AS daily_sub, t3.hacker_id, t3.name
FROM t3
INNER JOIN t2
ON t3.submission_date = t2.submission_date
WHERE percentile = 1
GROUP BY 1, 3, 4;