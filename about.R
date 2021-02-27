function(){
	tabPanel("About",
		HTML("<h1> Chi Zhang</h1>
        <p> 
        The project is the third part of the project 1 about the vaccine strategy in Ontario. 
        The best strategy is supposed to have a higher protection rate and less people infected.
        Less people being infected means: 1) the total number of people who get infected should be small. 2) the daily increase in the number of infected people should be decreasing or small.
        A higher protection rata means: 1) higher proportion of people who have be given 2 shots of vaccines. 2) higher vaccination rate of a spefic age-sex group (for example, the elderly).
        </p>
        
        <p>
        Ontario is currently in the first phase of vaccine distribution, which focus on the vaccination of people related to residents of long-term care homes, high-risk retirement homes, and first nations elder care homes and health care workers.
        March marks the beginning of the second phase of vaccine distribution in Ontario, in which older adults, other people who live and work in high-risk congregate settings, and essential works will be given higher pririoty.
        By the end of September, the general public vaccination phase is assumed to be complete in that the people with high-risk of contracting covid have already been vaccinated and the overall vaccinated rate is satisfactory.
        According to the vaccination plan of Ontario, 5.8 million of doses are expected to have been administrated by August, which is approximately equivalent to a coverage of 2.9 million people.
        </p>
        
        <p>
        The population of Ontario is divided by age and sex in this project, because the probability of a person getting infected varies with the age-sex groups. 
        Moreover, some specific groups enjoy priorities in vaccine distribution. 
        
        To simplify the simulation of vaccination, a relatively small number of population will be sampled according to the real demographics in Ontario.
        The daily vaccine administration capacity will be scaled accordingly.
        </p>
        
        <p>
        The efficacy of the Pfizer/BioNTech vaccine and the Moderna vaccine, the only 2 approved covid-19 vaccine in Canada, the vaccine administration capacity, and the effective reproduction rate are all based on the real data obtained from the website of the government of Ontario.
        The actual efficicacy of vaccines after mixing remains unknown, since the relevant study is still in process.  
        .85 is merely an assumption and can be modified to explore the realistic values of unknowns.
        </p>

        
        <p>
        The strategies are to be examined in this project can be modified using 3 radiobuttons on the top left of the webpage.
        If mixing vaccines are allowedd, then there is no need for the second dose to be of the same type of the first dose, despite potentially lower efficacy after fully vaccination.
        If oscillation of vaccine supplies is set to be true, then the daily vaccine supply and administration capacity is subject to change. 
        In reality, due to factors like bad weather, it is impractical to assume constant supplies over a long time period, so modelling the daily supplies using a uniform distribution may help make the simulation more realistic.
        If the elderly priority is set to be true, a vaccine will be given to the people from the oldest age group with the pre-specified probability.
        
        Instead of assuming immediate transmission of disease, we can model the distribution of the time between the date of getting infected and the date of starting to infecting others using a <a href=https://www.medrxiv.org/content/10.1101/2020.11.20.20235648v1.full.pdf target = '_blank'> lognormal distribution. </a> .
        </p>
        
        <p>
        The goal of this project is to find out whether or not mixing vaccines should be allowed to ensure a higher protection rate with a focus on the elder groups.
        More precisely, under what conditions should mixing vaccines preferred?
        It turns out that mixing vaccines is generally doing no good to increasing the protection rate unless there is huge oscilation in the vaccine supply.
        The elderly priority proves to play a pivotal role in ensuring the elder groups to be fully vaccinated first.
        In general, the higher priority is, the earlier the elder groups get fully vaccinated.
        </p>
		     "),
		
        HTML('
        <div style="clear: left;">
        Chi Zhang<br>
        Carleton University<br>
        <a href="https://github.com/chizhangzxc/project_1" target="_blank">Github</a> <br/>
        <a href="https://www.linkedin.com/in/chi-zhang-1b845792/" target="_blank">Linkedin</a> <br/>
        </p>'),
		value="about"
	)
}
