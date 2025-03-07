library(shiny)
library(shinydashboard)
library(tidyverse)
library(DBI)
library(RMySQL)
library(ggplot2)
library(plotly)
library(DT)
library(bs4Dash)

ui <- dashboardPage(
  dark = NULL,
  help = NULL,
  fullscreen = TRUE, 
  
  title = "NOBAR",
  header = dashboardHeader(title = span("NOBAR", style = "font-family: 'Poppins', sans-serif; color: #C3BFD8; font-weight: bold;")),
  sidebar = dashboardSidebar(
    sidebarMenu(
      menuItem("Homepage", tabName = "home", icon = icon("home")),
      menuItem("Movie", tabName = "movie", icon = icon("film")),
      menuItem("Genre", tabName = "genre", icon = icon("tags")),
      menuItem("Review", tabName = "review", icon = icon("comments")),
      menuItem("Top Movie", tabName = "top_movie", icon = icon("star")),
      menuItem("Team NOBAR", tabName = "team_NOBAR", icon = icon("person"))
    )
  ),
  controlbar = dashboardControlbar(),
  footer = dashboardFooter("© 2025 NOBAR - Dibuat dengan 🍿 oleh Tim NOBAR."),
  
  body = dashboardBody(
    # ✨ Styling CSS langsung di UI
    tags$head(tags$style(HTML('
      @import url("https://fonts.googleapis.com/css2?family=Poppins:wght@400;700&display=swap");

      body { 
        background-color: #FCF3E3; 
        color: #013D5A; 
        font-family: "Poppins", sans-serif; 
      }

      h2, h3, h4 { 
        color: #013D5A; 
        font-weight: 700; 
      }

      .box, .dataTables_wrapper { 
        background-color: #C3BFD8; 
        border-radius: 12px; 
        color: #013D5A !important;
      }

      .value-box { 
        background-color: #FAA258; 
        color: #013D5A !important; 
        border-radius: 10px; 
      }

      .main-header .logo { 
        background-color: #013D5A; 
        color: #FCF3E3; 
        font-weight: bold; 
      }

      .main-footer { 
        background-color: #FAA258; 
        color: #013D5A; 
        text-align: center; 
        padding: 12px; 
        font-size: 14px; 
      }

      .custom-comment { 
        background-color: #708C69; 
        padding: 12px; 
        border-left: 5px solid #FAA258; 
        border-radius: 10px; 
        margin-top: 12px; 
        font-style: italic; 
        color: #FCF3E3; 
      }
    '))),
    
    tabItems(
      tabItem("home",
              h2("🍿 Film ketemu, makanan tetap hangat – bareng NOBAR."),
              fluidRow(
                valueBoxOutput("totalFilms"),
                valueBoxOutput("totalGenres"),
                valueBoxOutput("averageRating")
              ),
              box(title = "📖 Apa itu NOBAR!?", width = 12, status = "info",
                  p("Platform ini bertujuan untuk menghadirkan pengalaman terbaik bagi pecinta film melalui NOBAR! Dengan database terpercaya, pengguna dapat menelusuri film berdasarkan genre, tahun rilis, atau rating tertinggi. 
                    Bergabunglah dan temukan tontonan terbaik di NOBAR! 🚀🍿✨"     
                  )),
              box(title = "🛠 Cara Menggunakan Platform Ini", width = 12, status = "success",
                  p("Di NOBAR!, Anda dapat mencari dan menjelajahi film berdasarkan berbagai kategori. Gunakan fitur filter & pencarian untuk menemukan film favorit Anda dengan mudah. Temukan rekomendasi terbaik dan nikmati pengalaman menonton yang lebih seru! 🚀🍿"
                  )
              ),
              fluidRow(
                box(title = "📊 Distribusi Genre", width = 6, plotlyOutput("genrePlot")),
                box(title = "⭐ Distribusi Rating Film", width = 6, plotlyOutput("ratingPlot"))
              ),
              fluidRow(
                box(title = "🎬 3 Film Terbaru", width = 12, dataTableOutput("recentFilms"))
              )
      ),
      
      tabItem("movie",
              h2("🎥 Daftar Film"),
              fluidRow(
                column(4, selectInput("selectedMovieGenre", "Pilih Genre:", choices = c("Semua"), selected = "Semua")),
                column(4, selectInput("selectedDirector", "Pilih Sutradara:", choices = c("Semua"), selected = "Semua")),
                column(4, selectInput("selectedRating", "Pilih Kategori Rating:", choices = c("Semua", "Above 8", "6-7", "Below 6"), selected = "Semua"))
              ),
              box(width = 12, dataTableOutput("filmTable"))
      ),
      
      tabItem("genre",
              h2("📂 Cari Film Berdasarkan Genre"),
              fluidRow(
                column(6, selectInput("selectedGenre", "Pilih Genre:", choices = c("Semua"), selected = "Semua")),
                column(6, selectInput("selectedYear", "Pilih Tahun:", choices = c("Semua"), selected = "Semua"))
              ),
              box(width = 12, dataTableOutput("genreTable")),
              fluidRow(
                box(title = "🎭 Distribusi Film Berdasarkan Genre", width = 6, solidHeader = TRUE, plotlyOutput("genreDistPlot")),
                box(title = "📆 Distribusi Film Berdasarkan Tahun", width = 6, solidHeader = TRUE, plotlyOutput("yearDistPlot"))
              )
      ),
      
      tabItem("review",
              h2("💬 Ulasan Film"),
              fluidRow(selectInput("selectedReviewMovie", "Pilih Film:", choices = c("Semua"), selected = "Semua")),
              fluidRow(valueBoxOutput("totalReviews"), valueBoxOutput("averageReviewRating")),
              box(width = 12, dataTableOutput("reviewTable"))
      ),
      
      tabItem("top_movie",
              h2("🌟 Film dengan Rating Tertinggi"),
              uiOutput("topMovieBox"),
              box(title = "🏆 5 Film Teratas", width = 12, dataTableOutput("topMovieTable"))
      ),
      
      tabItem("team_NOBAR",
              h2("👥 Kenalan dengan Tim NOBAR Yuk!!"),
              fluidRow(
                box(title = "Database Manager", width = 12, align = "center", imageOutput("uccang", width = "100%", height = "100%"))
              ),
              fluidRow(
                box(title = "Front End Developer", width = 12, align = "center", imageOutput("abil", width = "100%", height = "100%"))
              ),
              fluidRow(
                box(title = "Back End Developer", width = 12, align = "center", imageOutput("dilla", width = "100%", height = "100%"))
              ),
              fluidRow(
                box(title = "Designer Database", width = 12, align = "center", imageOutput("aini", width = "100%", height = "100%"))
              ),
              fluidRow(
                box(title = "Technical Writer", width = 12, align = "center", imageOutput("wina", width = "100%", height = "100%"))
              )
      )
    )
  )
)