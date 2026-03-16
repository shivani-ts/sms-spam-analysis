-- ============================================================
-- spam_analysis.sql
-- SMS Spam Analysis - Pattern Detection & Signal Evaluation
-- Author: D. Shivani
-- ============================================================
-- Assumes a table: messages(message_id, label, content)
-- label: 'spam' or 'ham'
-- ============================================================


-- ------------------------------------------------------------
-- SECTION 1: Dataset overview
-- ------------------------------------------------------------

-- How many messages, and what is the overall spam rate?
SELECT
    COUNT(*)                                            AS total_messages,
    SUM(CASE WHEN label = 'spam' THEN 1 ELSE 0 END)    AS spam_count,
    SUM(CASE WHEN label = 'ham'  THEN 1 ELSE 0 END)    AS ham_count,
    ROUND(
        100.0 * SUM(CASE WHEN label = 'spam' THEN 1 ELSE 0 END) / COUNT(*), 1
    )                                                   AS spam_rate_pct
FROM messages;


-- ------------------------------------------------------------
-- SECTION 2: Message length
-- ------------------------------------------------------------

-- Are spam messages longer or shorter than legitimate ones?
SELECT
    label,
    ROUND(AVG(LENGTH(content)), 0)      AS avg_length,
    MIN(LENGTH(content))                AS min_length,
    MAX(LENGTH(content))                AS max_length,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY LENGTH(content)) AS median_length
FROM messages
GROUP BY label;


-- ------------------------------------------------------------
-- SECTION 3: Spam signal detection
-- ------------------------------------------------------------

-- Signal 1: Messages containing a phone number
-- Phone numbers are a strong spam signal - spammers want you to call them
SELECT
    label,
    COUNT(*)                            AS total,
    SUM(CASE WHEN content ~ '\d{5,}'
             THEN 1 ELSE 0 END)        AS contains_phone,
    ROUND(
        100.0 * SUM(CASE WHEN content ~ '\d{5,}'
                         THEN 1 ELSE 0 END) / COUNT(*), 1
    )                                  AS phone_rate_pct
FROM messages
GROUP BY label;


-- Signal 2: Messages containing a URL
SELECT
    label,
    COUNT(*)                            AS total,
    SUM(CASE WHEN content ILIKE '%http%'
              OR content ILIKE '%www.%'
              OR content ILIKE '%.com%'
             THEN 1 ELSE 0 END)        AS contains_url,
    ROUND(
        100.0 * SUM(CASE WHEN content ILIKE '%http%'
                          OR content ILIKE '%www.%'
                          OR content ILIKE '%.com%'
                         THEN 1 ELSE 0 END) / COUNT(*), 1
    )                                  AS url_rate_pct
FROM messages
GROUP BY label;


-- Signal 3: Prize and urgency keywords
SELECT
    label,
    COUNT(*)                            AS total,
    SUM(CASE WHEN content ILIKE '%free%'
              OR content ILIKE '%winner%'
              OR content ILIKE '%won%'
              OR content ILIKE '%prize%'
              OR content ILIKE '%claim%'
              OR content ILIKE '%urgent%'
             THEN 1 ELSE 0 END)        AS contains_keywords,
    ROUND(
        100.0 * SUM(CASE WHEN content ILIKE '%free%'
                          OR content ILIKE '%winner%'
                          OR content ILIKE '%won%'
                          OR content ILIKE '%prize%'
                          OR content ILIKE '%claim%'
                          OR content ILIKE '%urgent%'
                         THEN 1 ELSE 0 END) / COUNT(*), 1
    )                                  AS keyword_rate_pct
FROM messages
GROUP BY label;


-- ------------------------------------------------------------
-- SECTION 4: Combined rule evaluation
-- ------------------------------------------------------------
-- How well does flagging ANY of the three signals work?

WITH flagged AS (
    SELECT
        message_id,
        label,
        CASE
            WHEN content ~ '\d{5,}'
              OR content ILIKE '%http%' OR content ILIKE '%www.%'
              OR content ILIKE '%free%' OR content ILIKE '%winner%'
              OR content ILIKE '%prize%' OR content ILIKE '%claim%'
              OR content ILIKE '%urgent%'
            THEN 'flagged'
            ELSE 'not_flagged'
        END AS prediction
    FROM messages
)
SELECT
    prediction,
    label,
    COUNT(*) AS count
FROM flagged
GROUP BY prediction, label
ORDER BY prediction, label;


-- ------------------------------------------------------------
-- SECTION 5: Most common words in spam
-- ------------------------------------------------------------
-- A simple way to spot new spam patterns without reading every message

SELECT
    word,
    COUNT(*) AS frequency
FROM (
    SELECT
        LOWER(REGEXP_SPLIT_TO_TABLE(content, '\s+')) AS word
    FROM messages
    WHERE label = 'spam'
) words
WHERE LENGTH(word) > 3
  AND word NOT IN ('that', 'this', 'with', 'have', 'from', 'your', 'will', 'been', 'they', 'were')
GROUP BY word
ORDER BY frequency DESC
LIMIT 30;
