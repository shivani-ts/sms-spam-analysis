# ============================================================
# spam_analysis.R
# SMS Spam Analysis - Statistical Analysis & Visualisation
# Author: D. Shivani
# ============================================================
# Dataset: SMS Spam Collection (UCI)
# https://archive.ics.uci.edu/dataset/228/sms+spam+collection
#
# Dependencies: tidyverse, ggplot2, scales
# Install: install.packages(c("tidyverse", "ggplot2", "scales"))
# ============================================================

library(tidyverse)
library(ggplot2)
library(scales)


# ------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------

messages <- read_tsv(
    "data/SMSSpamCollection",
    col_names = c("label", "content"),
    show_col_types = FALSE
) %>%
    mutate(
        char_len     = nchar(content),
        has_phone    = str_detect(content, "\\d{5,}"),
        has_url      = str_detect(tolower(content), "http|www\\.|.com"),
        has_keywords = str_detect(tolower(content), "free|winner|won|prize|claim|urgent")
    )

cat("Dataset loaded:", nrow(messages), "messages\n")


# ------------------------------------------------------------
# 2. Basic overview
# ------------------------------------------------------------

overview <- messages %>%
    count(label) %>%
    mutate(pct = round(n / sum(n) * 100, 1))

cat("\n--- Message counts ---\n")
print(overview)


# ------------------------------------------------------------
# 3. Message length comparison
# ------------------------------------------------------------

length_stats <- messages %>%
    group_by(label) %>%
    summarise(
        avg_length    = round(mean(char_len), 0),
        median_length = median(char_len),
        max_length    = max(char_len),
        .groups       = "drop"
    )

cat("\n--- Message length by label ---\n")
print(length_stats)

# Statistical test: are spam messages significantly longer?
wilcox_test <- wilcox.test(char_len ~ label, data = messages)
cat("\nWilcoxon test p-value:", round(wilcox_test$p.value, 6), "\n")
cat("Interpretation:", ifelse(wilcox_test$p.value < 0.05,
    "Significant difference in length between spam and ham.",
    "No significant difference."), "\n")


# ------------------------------------------------------------
# 4. Signal strength
# ------------------------------------------------------------

signal_results <- messages %>%
    group_by(label) %>%
    summarise(
        phone_pct    = round(mean(has_phone)    * 100, 1),
        url_pct      = round(mean(has_url)      * 100, 1),
        keyword_pct  = round(mean(has_keywords) * 100, 1),
        .groups      = "drop"
    )

cat("\n--- Signal presence by label (%) ---\n")
print(signal_results)


# ------------------------------------------------------------
# 5. Rule-based classifier evaluation
# ------------------------------------------------------------

messages_scored <- messages %>%
    mutate(
        predicted = if_else(
            has_phone | has_url | has_keywords, "spam", "ham"
        )
    )

# Confusion matrix
conf <- table(Predicted = messages_scored$predicted,
              Actual    = messages_scored$label)
cat("\n--- Confusion matrix ---\n")
print(conf)

tp <- conf["spam", "spam"]
fp <- conf["spam", "ham"]
fn <- conf["ham",  "spam"]

precision <- round(tp / (tp + fp) * 100, 1)
recall    <- round(tp / (tp + fn) * 100, 1)
f1        <- round(2 * precision * recall / (precision + recall), 1)

cat("\nPrecision:", precision, "%\n")
cat("Recall:   ", recall,    "%\n")
cat("F1:       ", f1,        "\n")


# ------------------------------------------------------------
# 6. Visualisations
# ------------------------------------------------------------

# Plot 1: Spam vs ham count
p1 <- ggplot(overview, aes(x = label, y = n, fill = label)) +
    geom_col(width = 0.5) +
    geom_text(aes(label = paste0(n, " (", pct, "%)")), vjust = -0.4, size = 4) +
    scale_fill_manual(values = c(ham = "#639922", spam = "#E24B4A"), guide = "none") +
    scale_y_continuous(limits = c(0, 5500)) +
    labs(title = "Message distribution", x = NULL, y = "Count") +
    theme_minimal(base_size = 12)

ggsave("plot_01_distribution.png", p1, width = 5, height = 4, dpi = 150)
cat("\nSaved: plot_01_distribution.png\n")


# Plot 2: Message length distribution
p2 <- ggplot(messages %>% filter(char_len < 200),
             aes(x = char_len, fill = label)) +
    geom_histogram(binwidth = 10, alpha = 0.7, position = "identity") +
    scale_fill_manual(values = c(ham = "#639922", spam = "#E24B4A"),
                      labels = c("Legitimate", "Spam")) +
    labs(
        title    = "Message length: spam vs legitimate",
        subtitle = "Spam messages tend to be longer",
        x        = "Character length",
        y        = "Count",
        fill     = NULL
    ) +
    theme_minimal(base_size = 12)

ggsave("plot_02_length.png", p2, width = 7, height = 4, dpi = 150)
cat("Saved: plot_02_length.png\n")


# Plot 3: Signal comparison
signal_plot <- signal_results %>%
    pivot_longer(cols = c(phone_pct, url_pct, keyword_pct),
                 names_to = "signal", values_to = "pct") %>%
    mutate(signal = recode(signal,
        phone_pct   = "Phone number",
        url_pct     = "URL",
        keyword_pct = "Prize/urgency keywords"
    ))

p3 <- ggplot(signal_plot, aes(x = signal, y = pct, fill = label)) +
    geom_col(position = "dodge", width = 0.6) +
    geom_text(aes(label = paste0(pct, "%")),
              position = position_dodge(width = 0.6),
              vjust = -0.4, size = 3.5) +
    scale_fill_manual(values = c(ham = "#639922", spam = "#E24B4A"),
                      labels = c("Legitimate", "Spam")) +
    scale_y_continuous(limits = c(0, 55), labels = label_percent(scale = 1)) +
    labs(
        title    = "Signal presence: spam vs legitimate",
        subtitle = "All three signals are far more common in spam",
        x        = NULL,
        y        = "% of messages",
        fill     = NULL
    ) +
    theme_minimal(base_size = 12)

ggsave("plot_03_signals.png", p3, width = 7, height = 4, dpi = 150)
cat("Saved: plot_03_signals.png\n")

cat("\nAnalysis complete.\n")
