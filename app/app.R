library(shiny)
library(shinydashboard)
library(tidyverse)
library(DBI)
library(RMySQL)
library(ggplot2)
library(plotly)
library(DT)
library(bs4Dash)

source("ui.R")
source("server.R")

shinyApp(ui, server)