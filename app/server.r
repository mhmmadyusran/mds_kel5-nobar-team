library(shiny)
library(shinydashboard)
library(tidyverse)
library(DBI)
library(RMySQL)
library(ggplot2)
library(plotly)
library(DT)
library(bs4Dash)

# Server
server <- function(input, output, session) {
  
  # Koneksi Tunggal ke Database
  con <- dbConnect(
    RMySQL::MySQL(), 
    dbname = "mds_5", 
    host = "localhost", 
    username = "root", 
    password = "", 
    port = 3306
  )

  
  # Pastikan Koneksi Ditutup Saat Aplikasi Berhenti
  onStop(function() {
    dbDisconnect(con)
  })
  
  # Fungsi Query Aman
  def_safe_query <- function(query) {
    tryCatch({
      dbGetQuery(con, query)
    }, error = function(e) {
      warning(paste("Gagal mengambil data:", e$message))
      NULL
    })
  }
  
  # Tab Homepage
  # Query untuk menghitung Total Film
  output$totalFilms <- renderValueBox({
    query <- "SELECT COUNT(*) AS total FROM films"
    result <- def_safe_query(query)
    valueBox(result$total, "Total Film", icon = icon("film"), color = "primary")
  })
  
  # Query untuk menghitung Total Genre
  output$totalGenres <- renderValueBox({
    query <- "SELECT COUNT(DISTINCT genre) AS total FROM films"
    result <- def_safe_query(query)
    valueBox(result$total, "Total Genre", icon = icon("tags"), color = "info")
  })
  
  # Query untuk menghitung Rata-rata Rating
  output$averageRating <- renderValueBox({
    query <- "SELECT ROUND(AVG(film_rating), 1) AS avg_rating FROM films"
    result <- def_safe_query(query)
    valueBox(result$avg_rating, "Rata-rata Rating", icon = icon("star"), color = "warning")
  })
  
  # Query untuk membuat plot distribusi genre
  output$genrePlot <- renderPlotly({
    query_genre_count <- "SELECT genre, CAST(COUNT(*) AS DOUBLE) AS jumlah FROM films GROUP BY genre"
    genre_data <- def_safe_query(query_genre_count)
    plot_ly(genre_data, x = ~genre, y = ~jumlah, type = "bar", marker = list(color = "#2a4562")) %>%
      layout(title = "Jumlah Film per Genre", xaxis = list(title = "Genre", tickangle = -45), yaxis = list(title = "Jumlah"))
  })
  
  # Query untuk membuat plot distribusi rating
  output$ratingPlot <- renderPlotly({
    query_rating <- "SELECT film_rating FROM films"
    rating_data <- def_safe_query(query_rating)
    plot_ly(rating_data, x = ~film_rating, type = "histogram",
            marker = list(color = "#f1e6d2", line = list(color = "#210706", width = 0.5)),
            xbins = list(start = 4, end = 9, size = 0.5)) %>%
      layout(title = "Distribusi Rating Film",
             xaxis = list(title = "Rating", dtick = 0.5),
             yaxis = list(title = "Jumlah"))
  })
  
  # Query untuk mendapatkan film terbaru
  output$recentFilms <- renderDataTable({
    query_recent_films <- "SELECT title, genre, release_year, film_rating, 
                            (SELECT director_name FROM directors d WHERE d.director_id = f.director_id) AS director_name 
                            FROM films f ORDER BY release_year DESC LIMIT 3"
    recent_films <- def_safe_query(query_recent_films)
    datatable(recent_films, options = list(pageLength = 3))
  })
  
  # Movie
  # Query untuk mendapatkan data film dengan sutradara dan aktor
  
  # Ambil data film dari database hanya sekali
  film_data <- reactive({
    query_film_data <- "SELECT f.film_id, f.title, f.genre, f.film_rating, f.duration, f.release_year, 
                        d.director_name, 
                        COALESCE(GROUP_CONCAT(a.actor_name SEPARATOR ', '), 'Tidak ada data') AS Aktor 
                        FROM films f 
                        JOIN directors d ON f.director_id = d.director_id 
                        LEFT JOIN casting c ON f.film_id = c.film_id 
                        LEFT JOIN actors a ON c.actor_id = a.actor_id 
                        GROUP BY f.film_id"
    def_safe_query(query_film_data)
  })
  
  # Update dropdown
  observe({
    req(film_data())
    
    updateSelectInput(session, "selectedMovieGenre", choices = c("Semua", sort(unique(film_data()$genre))))
    updateSelectInput(session, "selectedDirector", choices = c("Semua", sort(unique(film_data()$director_name))))
  })
  
  # Render Tabel Film
  output$filmTable <- renderDataTable({
    req(film_data())
    
    film_query <- "SELECT f.film_id, f.title, f.genre, f.film_rating, f.duration, f.release_year, 
                   d.director_name, 
                   COALESCE(GROUP_CONCAT(a.actor_name SEPARATOR ', '), 'Tidak ada data') AS Aktor 
                   FROM films f 
                   JOIN directors d ON f.director_id = d.director_id 
                   LEFT JOIN casting c ON f.film_id = c.film_id 
                   LEFT JOIN actors a ON c.actor_id = a.actor_id 
                   WHERE 1=1"
    
    # Filter SQL berdasarkan input
    if (input$selectedMovieGenre != "Semua") {
      film_query <- paste0(film_query, " AND f.genre = '", input$selectedMovieGenre, "'")
    }
    if (input$selectedDirector != "Semua") {
      film_query <- paste0(film_query, " AND d.director_name = '", input$selectedDirector, "'")
    }
    if (input$selectedRating != "Semua") {
      if (input$selectedRating == "Above 8") {
        film_query <- paste0(film_query, " AND f.film_rating >= 8")
      } else if (input$selectedRating == "6-7") {
        film_query <- paste0(film_query, " AND f.film_rating >= 6 AND f.film_rating < 8")
      } else if (input$selectedRating == "Below 6") {
        film_query <- paste0(film_query, " AND f.film_rating < 6")
      }
    }
    
    film_query <- paste0(film_query, " GROUP BY f.film_id")
    film_data_filtered <- def_safe_query(film_query)
    
    # Ubah nama kolom agar lebih user-friendly
    film_data_filtered <- film_data_filtered %>% select(
      Judul = title, 
      Genre = genre, 
      Rating = film_rating, 
      Aktor = Aktor, 
      Sutradara = director_name, 
      Durasi = duration
    )
    
    datatable(film_data_filtered, options = list(pageLength = 10, autoWidth = TRUE), class = "display")
  })
  
  # Query untuk mendapatkan mencari film berdasarkan genre dan tahun
  filtered_data <- reactive({
    req(film_data()) 
    data <- film_data()
    
    if (input$selectedGenre != "Semua") {
      data <- data[data$genre == input$selectedGenre, ]
    }
    
    if (input$selectedYear != "Semua") {
      data <- data[data$release_year == input$selectedYear, ]
    }
    
    return(data)
  })
  
  # Update Dropdown Pilihan Genre dan Tahun Secara Dinamis
  observe({
    req(film_data())
    
    updateSelectInput(session, "selectedGenre", choices = c("Semua", sort(unique(film_data()$genre))), selected = "Semua")
    updateSelectInput(session, "selectedYear", choices = c("Semua", sort(unique(film_data()$release_year), decreasing = TRUE)), selected = "Semua")
  })
  
  # Tabel berdasarkan Genre
  output$genreTable <- renderDataTable({
    req(filtered_data())
    
    filtered_data() %>% 
      select(Genre = genre, Judul = title, Tahun = release_year, Rating = film_rating, Aktor = Aktor) %>% 
      datatable(options = list(pageLength = 10))
  })
  
  # Plot Distribusi Film Berdasarkan Genre
  output$genreDistPlot <- renderPlotly({
    req(filtered_data())
    
    genre_count <- filtered_data() %>% count(genre)
    
    plot_ly(genre_count, x = ~n, y = ~reorder(genre, n), type = "bar", orientation = 'h',
            marker = list(color = "#2a4562")) %>%
      layout(title = "Distribusi Film Berdasarkan Genre",
             xaxis = list(title = "Jumlah"),
             yaxis = list(title = "Genre"))
  })
  
  # Plot Distribusi Film Berdasarkan Tahun
  output$yearDistPlot <- renderPlotly({
    query_year <- "SELECT release_year AS Tahun, COUNT(*) AS jumlah FROM films WHERE 1=1"
    
    if (input$selectedGenre != "Semua") {
      query_year <- paste0(query_year, " AND genre = '", input$selectedGenre, "'")
    }
    if (input$selectedYear != "Semua") {
      query_year <- paste0(query_year, " AND release_year = '", input$selectedYear, "'")
    }
    
    query_year <- paste0(query_year, " GROUP BY release_year ORDER BY release_year")
    year_data <- def_safe_query(query_year)
    
    year_data$Tahun <- as.factor(year_data$Tahun)
    
    plot_ly(year_data, x = ~Tahun, y = ~jumlah, type = "bar",
            marker = list(color = "#FAA258")) %>%
      layout(
        title = "Distribusi Film Berdasarkan Tahun",
        xaxis = list(
          title = "Tahun",
          tickangle = -45,
          type = "category"
        ),
        yaxis = list(title = "Jumlah Film")
      )
  })
  
  # Review
  # Daftar Film untuk Dropdown Review
  observe({
    film_list <- def_safe_query("SELECT DISTINCT title FROM films")
    if (!is.null(film_list) && nrow(film_list) > 0) {
      updateSelectInput(session, "selectedReviewMovie", choices = c("Semua", sort(film_list$title)))
    }
  })
  
  # Ambil Data Review dengan Nama Film Ditampilkan
  review_data <- reactive({
    query <- "SELECT f.title AS Film, rev.reviewer_name AS Nama_Reviewer, 
                   r.review_rating AS Rating, r.review_content AS Komentar, r.review_date AS Tanggal_Review
            FROM films f
            LEFT JOIN reviews r ON f.film_id = r.film_id
            LEFT JOIN reviewers rev ON r.reviewer_id = rev.reviewer_id
            WHERE 1=1"
    
    # Tambahkan Filter Berdasarkan Film yang Dipilih
    if (input$selectedReviewMovie != "Semua") {
      safe_title <- dbQuoteString(con, input$selectedReviewMovie)  # Gunakan dbQuoteString untuk keamanan
      query <- paste0(query, " AND f.title = ", safe_title)
    }
    
    query <- paste0(query, " ORDER BY r.review_date DESC")
    result <- def_safe_query(query)
    
    # Jika tidak ada review, tetap tampilkan nama film
    if (is.null(result) || nrow(result) == 0) {
      result <- data.frame(
        "Film" = input$selectedReviewMovie,
        "Nama Reviewer" = "Tidak Ada Data",
        "Rating" = NA,
        "Komentar" = "Belum ada review untuk film ini.",
        "Tanggal Review" = NA
      )
    }
    
    return(result)
  })
  
  # Render DataTable Review
  output$reviewTable <- renderDataTable({
    datatable(review_data(), options = list(pageLength = 10, autoWidth = TRUE), class = "display")
  })
  
  # Ambil Data Jumlah Review & Rata-rata Rating dari Tabel Review
  review_summary <- reactive({
    data <- review_data()
    
    # Hitung jumlah review (hanya yang memiliki rating valid)
    total_reviews <- sum(!is.na(data$Rating))
    
    # Hitung rata-rata rating (hanya dari data yang valid)
    avg_rating <- ifelse(total_reviews > 0, round(mean(data$Rating, na.rm = TRUE), 1), "-")
    
    return(data.frame(total_reviews = total_reviews, avg_rating = avg_rating))
  })
  
  # Tampilkan Jumlah Review
  output$totalReviews <- renderValueBox({
    data <- review_summary()
    valueBox(data$total_reviews, "Total Review", icon = icon("comments"), color = "info")
  })
  
  # Tampilkan Rata-rata Rating dari Data yang Ditampilkan
  output$averageReviewRating <- renderValueBox({
    data <- review_summary()
    valueBox(data$avg_rating, "Rata-rata Rating", icon = icon("star"), color = "warning")
  })
  
  # Query untuk Film dengan Rating Tertinggi
  top_movie_data <- reactive({
    query_top_film <- "SELECT f.title, f.release_year, 
                        ROUND(AVG(r.review_rating), 1) AS RataRating, 
                        (SELECT r2.review_content FROM reviews r2 
                          WHERE r2.film_id = f.film_id 
                          ORDER BY r2.review_rating DESC 
                          LIMIT 1) AS Komentar
                      FROM films f 
                      JOIN reviews r ON f.film_id = r.film_id 
                      GROUP BY f.film_id 
                      ORDER BY RataRating DESC 
                      LIMIT 1"
    
    result <- def_safe_query(query_top_film)
    
    # Jika tidak ada film, tampilkan default
    if (is.null(result) || nrow(result) == 0) {
      return(data.frame(title = "Tidak Ada Data", release_year = "", RataRating = "-", Komentar = ""))
    }
    
    return(result)
  })
  
  # Tampilkan Nama Film Teratas di UI
  output$topMovieTable <- renderDataTable({
    query_top_movies <- "SELECT f.title, f.release_year, 
                        ROUND(AVG(r.review_rating), 1) AS RataRating, 
                        COUNT(r.review_id) AS JumlahReview
                      FROM films f 
                      JOIN reviews r ON f.film_id = r.film_id 
                      GROUP BY f.film_id 
                      ORDER BY RataRating DESC 
                      LIMIT 5"
    
    top_movies <- def_safe_query(query_top_movies)
    datatable(top_movies, options = list(pageLength = 5))
  })
  
  # Pastikan box di UI bisa mengambil nilai langsung
  output$topMovieBox <- renderUI({
    movie_data <- top_movie_data()
    
    box(title = paste("🎖", movie_data$title, "(", movie_data$release_year, ")"), width = 12,
        p("⭐ Rata-rata Rating:", movie_data$RataRating),
        div(class = "custom-comment",
            strong("💬 Komentar Penonton dengan Rating Tertinggi:"),
            p(paste('"', movie_data$Komentar, '"'))
        )
    )
  })
  
  # Query untuk mendapatkan 5 Film Teratas berdasarkan rata-rata rating reviewers dan jumlah review
  output$topMovieTable <- renderDataTable({
    query_top_movies <- "SELECT f.title AS Judul, f.release_year AS Tahun,
                          ROUND(AVG(r.review_rating), 1) AS `Rata-rata Rating`,
                          COUNT(r.review_id) AS `Jumlah Review`
                        FROM films f 
                        JOIN reviews r ON f.film_id = r.film_id 
                        GROUP BY f.film_id 
                        ORDER BY `Rata-rata Rating` DESC 
                        LIMIT 5"
    
    top_movies <- def_safe_query(query_top_movies)
    
    # Jika tidak ada data, tampilkan placeholder
    if (is.null(top_movies) || nrow(top_movies) == 0) {
      top_movies <- data.frame(
        Judul = "Tidak Ada Data", 
        Tahun = "-", 
        `Rata-rata Rating` = "-", 
        `Jumlah Review` = "-"
      )
    }
    
    datatable(top_movies, options = list(pageLength = 5, autoWidth = TRUE), class = "display")
  })
  
  # Menampilkan gambar tim NOBAR
  output$uccang <- renderImage({
    list(src = "../images/uccang.png", contentType = "image/jpeg", width = "100%", height = "100%")
  }, deleteFile = FALSE)
  
  output$abil <- renderImage({
    list(src = "../images/abil.png", contentType = "image/jpeg", width = "100%", height = "100%")
  }, deleteFile = FALSE)
  
  output$dilla <- renderImage({
    list(src = "../images/dilla.png", contentType = "image/jpeg", width = "100%", height = "100%")
  }, deleteFile = FALSE)
  
  output$aini <- renderImage({
    list(src = "../images/aini.png", contentType = "image/jpeg", width = "100%", height = "100%")
  }, deleteFile = FALSE)
  
  output$wina <- renderImage({
    list(src = "../images/wina.png", contentType = "image/jpeg", width = "100%", height = "100%")
  }, deleteFile = FALSE)
}