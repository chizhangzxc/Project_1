source("checkpackages.R")

checkpackages("lubridate")
checkpackages("readxl")
checkpackages("shiny")
checkpackages("data.table")


shinyServer(function(input, output, session) {
  
  
  get_data <- reactive({
    N <- input$initialPopulationSize
    active_cases <- 12406
    forecast_length <- abs(time_length(interval(ymd(input$`Forecast length`),ymd("2021-02-27")), "days"))
    
    raw_data <- data.table(read_xlsx("Ontario.xlsx"))[,.(`Age group`,`Male cases`,`Male population`,`Female cases`,`Female population`)]
    
    total_cases <- sum(raw_data$`Male cases`, raw_data$`Female cases`)
    raw_data[, `Male infection proportion` := raw_data$`Male cases` / total_cases]
    raw_data[, `Male infection rate` := raw_data$`Male cases` / raw_data$`Male population`]
    
    raw_data[, `Female infection proportion` := raw_data$`Female cases` / total_cases]
    raw_data[, `Female infection rate` := raw_data$`Female cases` / raw_data$`Female population`]
    raw_data <- data.table(`Age group` = raw_data$`Age group`, 
                           Sex = rep(c('Male','Female'), each=10),
                           Cases = c(raw_data$`Male cases`,raw_data$`Female cases`), 
                           Population = c(raw_data$`Male population`,raw_data$`Male population`), 
                           `Infection proportion`=c(raw_data$`Male infection proportion`,raw_data$`Female infection proportion`), 
                           `Infection rate`=c(raw_data$`Male infection rate`,raw_data$`Female infection rate`))
    raw_data[, `Population density` := raw_data$Population / sum(raw_data$Population)]
    total_population <- sum(raw_data$Population)
    
    active_rate <- active_cases / sum(raw_data$Population)
    
    
    
    
    pop <- sample(1:20,size = input$initialPopulationSize,replace = TRUE, prob = raw_data$`Population density`)
    
    sampled_population <- data.table(`Age group` = raw_data$`Age group`[pop],
                                     Sex = raw_data$Sex[pop],
                                     Pfizer_1 = 0,
                                     Pfizer_2 = 0,
                                     Moderna_1 = 0,
                                     Moderna_2 = 0,
                                     Infected = -1)
    sampled_population <- sampled_population[order(-`Age group`)]
    
    Sample <-function(n, mean, max)
    {
      z = tabulate(sample.int(max*(n), (n)*(mean),replace =F) %% (n)+1, (n))
      return(z)
    }
    
    incubation_time <- ceiling(rlnorm(ceiling(input$initialPopulationSize*active_rate),1.79,.52))
    
    infected_population <- data.table(Incubation = incubation_time,
                                      Infected = Sample(ceiling(input$initialPopulationSize*active_rate), input$Rt_rate, max(incubation_time)))
    
    
    days <- 0
    
    if(input$mixing_vaccines == "false")
      vaccine_protection <- list('Pfizer_1' = input$Pfizer_dose1,
                                 'Pfizer_2' = input$Pfizer_dose2,
                                 'Moderna_1' = input$Moderna_dose1,
                                 'Moderna_2' = input$Moderna_dose2)
    else
    {
      vaccine_protection <- list('Pfizer_1' = input$Pfizer_dose1,
                                 'Pfizer_2' = input$Pfizer_dose2,
                                 'Moderna_1' = input$Moderna_dose1,
                                 'Moderna_2' = input$Moderna_dose2,
                                 'Second' = input$Second_dose)
    }
    
    
    while (days < forecast_length) 
    {
      moderna_capacity  <- input$Moderna_capacity * input$initialPopulationSize / total_population
      
      pfizer_capacity <- input$Pfizer_capacity * input$initialPopulationSize / total_population
      
      vaccine_capacity <- input$vaccine_administration * input$initialPopulationSize / total_population
      if(input$Oscillation == 'true')
      {
        moderna_capacity <- runif(1, min = moderna_capacity * (1-input$Vaccine_oscillation), max = moderna_capacity * (1+input$Vaccine_oscillation))
        pfizer_capacity <- runif(1, min = pfizer_capacity * (1-input$Vaccine_oscillation), max = pfizer_capacity * (1+input$Vaccine_oscillation))
        vaccine_capacity <- runif(1, min = vaccine_capacity * (1-input$Vaccine_oscillation), max = vaccine_capacity * (1+input$Vaccine_oscillation))
      }
      
      if(moderna_capacity + pfizer_capacity > vaccine_capacity)
      {
        proportion <- c(moderna_capacity, pfizer_capacity) / sum(moderna_capacity, pfizer_capacity)
        moderna_capacity <- proportion[1] * vaccine_capacity
        pfizer_capacity <- proportion[2] * vaccine_capacity
      }
      
      
      days <- days + 1
      #simulate the number who will get covid on the day
      infected_today <- infected_population[infected_population$Incubation == days & infected_population$Infected > 0]
      pfizer_taken <- 1
      moderna_taken <- 1
      vaccine_taken <- 1
      
      if(nrow(infected_today) > 0)
      {
        #simulate which age-sex the newly infected person belongs to
        for(patient in 1:sum(infected_today$Infected))
        {
          while(TRUE)
          {
            result <- sample(1:20, size = 1, prob = raw_data$`Infection proportion`)
            N <- sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1,.N]
            if(N > 0)
            {
              index <- sample(N,1)
              
              
              #find if the infected person has vaccines
              if(max(sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index][,.(Pfizer_1,Pfizer_2,Moderna_1,Moderna_2)])==0)
              {
                sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index]$Infected <- days
                infected_population <- rbind(infected_population, list(Incubation = days + ceiling(rlnorm(1,1.79,.52)),
                                                                       Infected = rpois(1,input$Rt_rate)))
              }
              else
              {
                vaccine_taken <- names(which.max(sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index][,.(Pfizer_1,Pfizer_2,Moderna_1,Moderna_2)][,.(Pfizer_1,Pfizer_2,Moderna_1,Moderna_2)]))
                if(input$mixing_vaccines == "false")
                  protection_rate <- vaccine_protection[vaccine_taken]
                else
                {
                  protection_rate <- vaccine_protection[vaccine_taken]
                  if(vaccine_taken == "Pfizer_2" & sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index][,.(Moderna_1)] > 0)
                    protection_rate <- vaccine_protection["Second"]
                  if(vaccine_taken == "Moderna_2" & sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index][,.(Pfizer_1)] > 0)
                    protection_rate <- vaccine_protection["Second"]
                }
                if(runif(1) > protection_rate)
                {
                  sampled_population[`Age group` == raw_data[result,]$`Age group` & Sex == raw_data[result,]$Sex & Infected==-1][index]$Infected <- days
                  infected_population <- rbind(infected_population, list(Incubation = days + ceiling(rlnorm(1,1.79,.52)),
                                                                         Infected = rpois(1,input$Rt_rate)))
                }
              }
              break
            }
            
          }
        }
      }
      
      
      while (pfizer_taken < pfizer_capacity) 
      {
        if(pfizer_taken + moderna_taken > vaccine_capacity)
          break
        if(input$mixing_vaccines == "false")
        {
          already_taken <- sampled_population[sampled_population$Pfizer_1 > 0 
                                              & sampled_population$Pfizer_1 + 28 < days 
                                              & sampled_population$Pfizer_2 == 0 
                                              & sampled_population$Infected == -1 
                                              & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))]
        }
        else
        {
          already_taken <- sampled_population[(sampled_population$Pfizer_1 > 0 | sampled_population$Moderna_1 > 0)
                                              & (sampled_population$Pfizer_1 + 28 < days & sampled_population$Moderna_1 + 28 < days) 
                                              & (sampled_population$Pfizer_2 == 0 & sampled_population$Moderna_2 == 0)
                                              & sampled_population$Infected == -1 
                                              & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))]
        }      
        # print(sampled_population[(sampled_population$Pfizer_1 | sampled_population$Moderna_1 > 0)])
        
        if(nrow(already_taken>0))
        {
          
          while (pfizer_taken < pfizer_capacity) 
          {         
            already_taken <- already_taken[order(-`Age group`)]
            
            if(input$elderly_first == 'true')
            {
              priority <- input$Elderly_priority
              if(runif(1) < priority)
                index <- 1
              else
                index <- sample(nrow(already_taken), 1)
            }
            else
              index <- sample(nrow(already_taken), 1)
            
            if(input$mixing_vaccines== "false")
              sampled_population[sampled_population$Pfizer_1 > 0 
                                 & sampled_population$Pfizer_1 + 28 < days 
                                 & sampled_population$Pfizer_2 == 0 
                                 & sampled_population$Infected == -1 
                                 & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))][index]$Pfizer_2 <- days
            else
              sampled_population[(sampled_population$Pfizer_1 > 0 | sampled_population$Moderna_1 > 0)
                                 & (sampled_population$Pfizer_1 + 28 < days & sampled_population$Moderna_1 + 28 < days )
                                 & (sampled_population$Pfizer_2 == 0 & sampled_population$Moderna_2 == 0)
                                 & sampled_population$Infected == -1 
                                 & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))][index]$Pfizer_2  <- days
            pfizer_taken <- pfizer_taken + 1
            
            
          }
        }
        else
          break
      }
      
      
      while (moderna_taken < moderna_capacity) 
      {
        if(pfizer_taken + moderna_taken > vaccine_capacity)
          break
        if(input$mixing_vaccines== "false")
          already_taken <- sampled_population[sampled_population$Moderna_1 > 0 
                                              & sampled_population$Moderna_1 + 28 < days 
                                              & sampled_population$Moderna_2 == 0 
                                              & sampled_population$Infected == -1
                                              & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))]
        else 
          already_taken <- sampled_population[(sampled_population$Pfizer_1 > 0 | sampled_population$Moderna_1 > 0)
                                              & (sampled_population$Pfizer_1 + 28 < days & sampled_population$Moderna_1 + 28 < days) 
                                              & (sampled_population$Pfizer_2 == 0 & sampled_population$Moderna_2 == 0)
                                              & sampled_population$Infected == -1 
                                              & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))] 
        
        if(nrow(already_taken>0))
        {
          
          while (moderna_taken < moderna_capacity) 
          {                 
            already_taken <- already_taken[order(-`Age group`)]
            
            if(input$elderly_first == 'true')
            {
              priority <- input$Elderly_priority
              if(runif(1) < priority)
                index <- 1
              else
                index <- sample(nrow(already_taken), 1)
            }
            else
              index <- sample(nrow(already_taken), 1)
            
            if(input$mixing_vaccines== "false")
              sampled_population[sampled_population$Moderna_1 > 0 
                                 & sampled_population$Moderna_1 + 28 < days 
                                 & sampled_population$Moderna_2 == 0 
                                 & sampled_population$Infected == -1
                                 & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))][index]$Moderna_2 <- days
            else 
              sampled_population[(sampled_population$Pfizer_1 > 0 | sampled_population$Moderna_1 > 0)
                                 & (sampled_population$Pfizer_1 + 28 < days & sampled_population$Moderna_1 + 28 < days) 
                                 & (sampled_population$Pfizer_2 == 0 & sampled_population$Moderna_2 == 0)
                                 & sampled_population$Infected == -1 
                                 & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))] [index]$Moderna_2 <- days
            moderna_taken <- moderna_taken + 1
          }
        }
        else
          break
      }
      
      
      while (pfizer_taken < pfizer_capacity) 
      {
        if(pfizer_taken + moderna_taken > vaccine_capacity)
          break
        not_vaccinated <- sampled_population[sampled_population$Pfizer_1 == 0 
                                             & sampled_population$Moderna_1 == 0 
                                             & sampled_population$Infected == -1
                                             & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))]
        
        # print(not_vaccinated[not_vaccinated$`Age group` == '0 to 9'])
        
        while(pfizer_taken < pfizer_capacity)
        {
          not_vaccinated <- not_vaccinated[order(-`Age group`)]
          
          if(input$elderly_first == 'true')
          {
            priority <- input$Elderly_priority
            if(runif(1) < priority)
              index <- 1
            else
              index <- sample(nrow(not_vaccinated), 1)
          }
          else
            index <- sample(nrow(not_vaccinated), 1)
          sampled_population[sampled_population$Pfizer_1 == 0 
                             & sampled_population$Moderna_1 == 0 
                             & sampled_population$Infected == -1
                             & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))][index]$Pfizer_1 <- days
          pfizer_taken <- pfizer_taken + 1
        }
      }
      
      
      
      while (moderna_taken < moderna_capacity) 
      {
        if(pfizer_taken + moderna_taken > vaccine_capacity)
          break
        not_vaccinated <- sampled_population[sampled_population$Pfizer_1 == 0 
                                             & sampled_population$Moderna_1 == 0 
                                             & sampled_population$Infected == -1
                                             & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))]
        
        # print(not_vaccinated[not_vaccinated$`Age group` == '0 to 9'])
        while(moderna_taken < moderna_capacity)
        {
          
          not_vaccinated <- not_vaccinated[order(-`Age group`)]
          
          if(input$elderly_first == 'true')
          {
            priority <- input$Elderly_priority
            if(runif(1) < priority)
              index <- 1
            else
              index <- sample(nrow(not_vaccinated), 1)
          }
          else
            index <- sample(nrow(not_vaccinated), 1)
          
          sampled_population[sampled_population$Pfizer_1 == 0 
                             & sampled_population$Moderna_1 == 0 
                             & sampled_population$Infected == -1
                             & !(sampled_population$`Age group` %in% c('10 to 19','0 to 9'))][index]$Moderna_1 <- days
          moderna_taken <- moderna_taken + 1
        }
      }
      
    }
    
    
    sampled_population
    
    
  })
  
  
  
  output$distPlot <- renderDataTable({
    raw_data <- get_data()
    result_data <- raw_data[,.(Infected = sum(Infected>0),`Fully vaccinated` = sum(Pfizer_2 > 0 | Moderna_2 > 0), Population = sum(Pfizer_1 >= 0)),.(`Age group`, Sex)]
    
    result_data <-rbind(result_data, list(`Age group` = "All", Sex = 'Both', Infected = sum(result_data$Infected), Population = sum(result_data$Population), `Fully vaccinated` = sum(result_data$`Fully vaccinated`)))
    result_data <- result_data[, 'Infection rate' := result_data$Infected / result_data$Population]
    result_data <- result_data[, 'Vaccinated rate' := result_data$`Fully vaccinated` / result_data$Population]
    
    
  })
  
  
  
  output$Infected <- renderPlot({
    forecast_length <- abs(time_length(interval(ymd(input$`Forecast length`),ymd("2021-02-27")), "days"))
    
    if(forecast_length > 0)
    {
      raw_data <- get_data()
      num_infected <- NULL
      for (days in 1:forecast_length)
      {
        # num_infected <- c(num_infected, data[data$Infected<=days & data$Infected > 0,.N])
        num_infected <- c(num_infected, raw_data[`Infected`==days,.N])
        
        
      }
      plot(x = seq(1,forecast_length,1), y = num_infected, type='l', xlab='Days', ylab='Number of people who get infected')
    }
  })
  
  
  
  output$FullyVaccinated <- renderPlot({
    forecast_length <- abs(time_length(interval(ymd(input$`Forecast length`),ymd("2021-02-27")), "days"))
    
    if(forecast_length > 0)
    {
      raw_data <- get_data()
      num_vaccinated <- NULL
      for (days in 1:forecast_length)
      {
        num_vaccinated <- c(num_vaccinated, raw_data[Moderna_2 == days | Pfizer_2 == days,.N])
      }
      plot(x = seq(1,forecast_length,1), y = cumsum(num_vaccinated)/input$initialPopulationSize, type='l', xlab='Days', ylab="Proportion of people have been give only 1 vaccine")
      
    }
    
  })
  
  output$OneVaccine <- renderPlot({
    forecast_length <- abs(time_length(interval(ymd(input$`Forecast length`),ymd("2021-02-27")), "days"))
    
    if(forecast_length > 0)
    {
      raw_data <- get_data()
      num_vaccinated <- NULL
      for (days in 1:forecast_length)
      {
        num_vaccinated <- c(num_vaccinated, raw_data[(Moderna_1 <= days & Moderna_1 > 0) | (Pfizer_1 <= days & Pfizer_1 > 0),.N] - raw_data[(Moderna_2 <= days & Moderna_2 > 0) | (Pfizer_2 <= days & Pfizer_2 > 0),.N])
      }
      plot(x = seq(1,forecast_length,1), y = (num_vaccinated)/input$initialPopulationSize, type='l', xlab='Days', ylab="Proportion of people have been given 2 vaccines")
      
    }
    
  })
  
  output$MixedVaccines <- renderPlot({
    forecast_length <- abs(time_length(interval(ymd(input$`Forecast length`),ymd("2021-02-27")), "days"))
    
    if(forecast_length > 0)
    {
      raw_data <- get_data()
      num_mixed <- NULL
      
      for(days in 1:forecast_length)
      {
        num_mixed <- c(num_mixed, raw_data[Moderna_1 > 0 & Pfizer_2 > 0 & Pfizer_2 <= days,.N] + raw_data[Pfizer_1 > 0 & Moderna_2 > 0 & Moderna_2 <= days,.N])
      }
      plot(x = seq(1, forecast_length, 1), y = num_mixed / input$initialPopulationSize, type = 'l', xlab = "Days", ylab = "Proportion of people who have been given mixed vaccines")
      
    }
    
  })
  
  observeEvent(input$reset,{
    session$reload()
  })
})