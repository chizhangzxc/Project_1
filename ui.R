
library(shiny)

shinyUI(fluidPage(

    titlePanel("Vaccine Strategy in Ontario pt.3 Chi Zhang"),
    submitButton("Submit"),
    # actionButton("table","Table"),
    actionButton("reset","Reset"),
    selectInput("select",
                "",
                c("about",
                  "forecast")),
    
    conditionalPanel("input.select != 'about'",
                     radioButtons(inputId = "mixing_vaccines",
                                  label = "Is mixing vaccines allowed?",
                                  choices = c("True" = "true",
                                              "False" = "false"),
                                  inline = TRUE),
                     radioButtons(inputId = "Oscillation",
                                  label = "Will there be oscillations in vaccine supplies?",
                                  choices = c("True" = 'true',
                                              "False" = "false"),
                                  inline = TRUE),
                     radioButtons(inputId = "elderly_first",
                                  label = "Will the elderly get vaccines first?",
                                  choices = c("True" = "true",
                                              "False" = "false"),
                                  inline = TRUE),
                     sidebarLayout(
                         sidebarPanel(
                             p("Beginning with a population of size:"),
                             numericInput("initialPopulationSize", "", 15000, 10000, 20000, 1000),
                             dateInput("Forecast length",
                                       "The end of our forecast:",
                                       min = "2021-02-27",
                                       max = "2021-09-30",
                                       value = "2021-02-27"),
                             p(HTML("<a href=https://covid-19.ontario.ca/data#age_and_gender' target = '_blank'>Government of Ontario</a>")),
                             numericInput("Rt_rate","The effective reproduction rate in Ontario found on the link above:",.99,0,2,.01),
                             
                             p(HTML("<a href=https://www.canada.ca/en/public-health/services/immunization/national-advisory-committee-on-immunization-naci/recommendations-use-covid-19-vaccines.html' target = '_blank'> All data pertaining to the vaccine efficacy can be found here</a>")),
                             
                             numericInput("Pfizer_dose1","Efficacy of Pfizer-BioNTech vaccine after the fist dose:",.52,0,1,.01),
                             numericInput("Moderna_dose1","Efficacy of Moderna vaccine after the fist dose:",.8,0,1,.01),
                             numericInput("Pfizer_dose2","Efficacy of Moderna vaccine after the fist dose:",.8,0,1,.01),
                             numericInput("Moderna_dose2","Efficacy of Moderna vaccine after the second dose:",.92,0,1,.01),
                             numericInput("Second_dose","Efficacy of the second vaccine after if two vaccines are mixed (Please note that the vaccine efficacy after mixing is merely a hypothesized value lacking clinical trials.):",.85,0,1,.01),
                             
                             p(HTML("<a href=https://www.canada.ca/en/public-health/services/diseases/2019-novel-coronavirus-infection/prevention-risks/covid-19-vaccine-treatment/vaccine-rollout.html#a4' target = '_blank'> Vaccine distribution.</a>")),
                             
                             numericInput("Pfizer_capacity","The number of Pfizer vaccines avaibale in Ontario per day (estimated for full population):", 26576, 20000,30000,100),
                             numericInput("Moderna_capacity","The number of Moderna vaccines avaibale in Ontario per day (estimated for full population):", 6771, 5000,10000,100),
                             p(HTML("<a href=https://covid-19.ontario.ca/covid-19-vaccines-ontario' target = '_blank'> Vaccine administration in Ontario</a>")),
                             
                             numericInput("vaccine_administration", "The daily doses administrated capacity (estimated for full population):", 21805, 15000, 25000, 100),
                             numericInput("Vaccine_oscillation", "The oscillation magnitude:", 0, 0, 1, .1),
                             numericInput("Elderly_priority", "The probability of a vaccine given to the oldest age group:", .5, 0, 1, .1)
                             ),
                         
                         mainPanel(
                         p(HTML("<a href=https://www.medrxiv.org/content/10.1101/2020.11.20.20235648v1.full.pdf target = '_blank'> The distribution of the incubation period can be found here. </a> 
                         The best strategy will have a lower infection rate, and in this example the results are not consistent, so there is no conclusion yet.
                                The default values in the sidebar on the left will be scaled according to the proportion of the initial population size to the real population in Ontario.")),
                         navlistPanel(tabPanel("Data Table",dataTableOutput("distPlot")),
                                      tabPanel("Daily increase of the infected",plotOutput('Infected')),
                                      tabPanel("Proportion of people have been give only 1 vaccine", plotOutput("OneVaccine")),
                                      tabPanel("Proportion of people have been given 2 vaccines", plotOutput("FullyVaccinated")),
                                      tabPanel("Proportion of people have been given mixied vaccines", plotOutput("MixedVaccines")))
                         )
                         )
                     ),
    conditionalPanel("input.select == 'about'", 
                     
                     mainPanel(
                         source("about.R")$value()
                     )
    )
    )
)
