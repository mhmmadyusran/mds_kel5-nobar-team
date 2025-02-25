library(shiny)
library(shinydashboard)
library(DBI)
library(DT)
library(dplyr)
library(RMySQL)

# 1. Konfigurasi Database DBngin
db_config <- list(
  host = "127.0.0.1",
  port = 3306,
  user = "root",
  password = "",
  dbname = "mds_5"
)

# 2. Membuat koneksi ke database MySQL
#con <- dbConnect(
#  MySQL(),
#  host = db_config$host,
#  port = db_config$port,
#  user = db_config$user,
#  password = db_config$password,
#  dbname = db_config$dbname
#)

#dbListTables(con)  # Menampilkan daftar tabel dalam database

library(pool)

pool <- dbPool(
  drv = RMySQL::MySQL(),
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password,
  dbname = db_config$dbname
)

onStop(function() {
  poolClose(pool)
})



# UI
ui <- dashboardPage(
  dashboardHeader(title = "Film Database"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Daftar Film", tabName = "film_list", icon = icon("film")),
      menuItem("Informasi Genre", tabName = "genre_info", icon = icon("tags")),
      menuItem("Review Film", tabName = "reviews", icon = icon("comments"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Halaman Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(title = "Total Film", width = 4, solidHeader = TRUE, status = "primary",
                    textOutput("total_films")),
                box(title = "Total Genre", width = 4, solidHeader = TRUE, status = "success",
                    textOutput("total_genres")),
                box(title = "Total Director", width = 4, solidHeader = TRUE, status = "warning",
                    textOutput("total_directors"))
              ),
              fluidRow(
                box(title = "Top Rated Film", width = 12, solidHeader = TRUE, status = "info",
                    textOutput("top_rated_film"))
              )
      ),
      
      # Halaman Daftar Film
      tabItem(tabName = "film_list",
              sidebarLayout(
                sidebarPanel(
                  selectInput("genre_filter", "Pilih Genre", choices = NULL),
                  selectInput("year_filter", "Pilih Tahun Rilis", choices = NULL),
                  selectInput("director_filter", "Pilih Director", choices = NULL),
                  textInput("film_name_filter", "Masukkan Nama Film", value = "")
                ),
                mainPanel(
                  DTOutput("film_table")
                )
              )
      ),
      
      # Halaman Informasi Genre
      tabItem(tabName = "genre_info",
              sidebarLayout(
                sidebarPanel(
                  selectInput("year_filter_genre", "Pilih Tahun Rilis", choices = NULL)
                ),
                mainPanel(
                  DTOutput("genre_table")
                )
              )
      ),
      
      # Halaman Review Film
      tabItem(tabName = "reviews",
              sidebarLayout(
                sidebarPanel(
                  textInput("film_name_filter_review", "Masukkan Nama Film", value = "")
                ),
                mainPanel(
                  DTOutput("review_table")
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  DB <- pool
  
  # Statistik Overview
  output$total_films <- renderText({
    total <- dbGetQuery(DB, "SELECT COUNT(*) AS total FROM films")
    paste("🎬", total$total, "Film")
  })
  
  output$total_genres <- renderText({
    total <- dbGetQuery(DB, "SELECT COUNT(DISTINCT genre) AS total FROM films")
    paste("📂", total$total, "Genre")
  })
  
  output$total_directors <- renderText({
    total <- dbGetQuery(DB, "SELECT COUNT(DISTINCT director) AS total FROM directors")
    paste("🎬", total$total, "Director")
  })
  
  output$top_rated_film <- renderText({
    top_film <- dbGetQuery(DB, "SELECT title FROM films ORDER BY film_rating DESC LIMIT 1")
    paste("⭐", top_film$title)
  })
  
  # Update pilihan genre
  observe({
    genres <- dbGetQuery(DB, "SELECT DISTINCT genre FROM films")
    updateSelectInput(session, "genre_filter", choices = c("Semua", genres$genre))
  })
  
  # Update pilihan tahun rilis
  observe({
    years <- dbGetQuery(DB, "SELECT DISTINCT release_year FROM films ORDER BY release_year DESC")
    updateSelectInput(session, "year_filter", choices = c("Semua", years$release_year))
    updateSelectInput(session, "year_filter_genre", choices = c("Semua", years$release_year))
  })
  
  # Update pilihan direktur
  observe({
    directors <- dbGetQuery(DB, "SELECT DISTINCT director FROM directors")
    updateSelectInput(session, "director_filter", choices = c("Semua", directors$director))
  })
  
  # Query Tabel Film
  output$film_table <- renderDT({
    query <- "SELECT f.title AS Judul_Film, f.genre AS Genre, f.film_rating AS Film_Rating, 
                     a.actor_name AS Actor, d.director AS Director, f.duration AS Duration
              FROM films f
              JOIN casting c ON f.film_id = c.film_id
              JOIN actors a ON c.actor_id = a.actor_id
              JOIN directors d ON f.director_id = d.director_id
              WHERE 1=1"
    
    if (input$genre_filter != "Semua") {
      query <- paste0(query, " AND f.genre = '", input$genre_filter, "'")
    }
    if (input$director_filter != "Semua") {
      query <- paste0(query, " AND d.director = '", input$director_filter, "'")
    }
    film_data <- dbGetQuery(DB, query)
    datatable(film_data)
  })
  
  # Query Tabel Genre
  output$genre_table <- renderDT({
    query <- "SELECT f.genre AS Genre, f.release_year AS Release_Year, f.title AS Title, 
                     f.film_rating AS Rating, a.actor_name AS Actor
              FROM films f
              JOIN casting c ON f.film_id = c.film_id
              JOIN actors a ON c.actor_id = a.actor_id
              WHERE 1=1"
    
    if (input$year_filter_genre != "Semua") {
      query <- paste0(query, " AND f.release_year = '", input$year_filter_genre, "'")
    }
    genre_data <- dbGetQuery(DB, query)
    datatable(genre_data)
  })
  
  # Query Tabel Review
  output$review_table <- renderDT({
    query <- paste0(
      "SELECT f.title AS Title, f.release_year AS Release_Year, 
              r.review_rating AS Review_Rating, r.review_content AS Review_Content
       FROM reviews r
       JOIN films f ON r.film_id = f.film_id
       WHERE f.title LIKE '%", input$film_name_filter_review, "%'"
    )
    review_data <- dbGetQuery(DB, query)
    datatable(review_data)
  })
}

# Run the app
shinyApp(ui = ui, server = server)
