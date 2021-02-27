library('tools')


checkpackages <- function(package2use){
  required.package <- package2use
  pkg = 0
  DEPSGet=NULL
  while(pkg < length(package2use)){#loop over all packages
    pkg=pkg+1
    #Expand the list of packages to include all of the dependencies
    DEPSGet = c(DEPSGet,unlist(package_dependencies(package2use[pkg],recursive=FALSE,
                                              which=c("Depends", "Imports", "LinkingTo" ))))
  
  }
  package2use = c(package2use,DEPSGet)
  rev(package_dependencies('rworldmap',recursive=FALSE,
                       which=c("Depends", "Imports", "LinkingTo" )))
  
  #When installing start from the one with the least dependencies and work your way up
  #only use the unique packages:
  package2use = rev(unique(package2use))
  cat(paste0("\n",'packages to be used for ',required.package, ': ', paste(package2use, collapse = ' ')))
  #Now cycle over the list of dependencies and libraries of interest and install and/or load them
    for(pk in 1:length(package2use)){
      package=package2use[pk]
    if (!package %in% installed.packages())
    {#First check globally
    print("line25")
      if (!package %in% installed.packages(lib=getwd())){#Then check locally
      # print("line27")
        # print(package)
        print(paste0('package ', package2use[pk], 'cannot be found and it will be instelled locally.'))
        install.packages(package,dependencies=FALSE,lib=getwd())#If neither then install locally
        # print("line29")
        library(package,character.only=TRUE,lib.loc=getwd())
        print(paste0('package ', package2use[pk], 'has been successfully loaded.'))
        # print("line31")
        #print(package)
      }else{
        # print("line34")
        #print(package)
        library(package,character.only=TRUE)#Already installed globally so load globally
        print(paste0('package ', package2use[pk], 'has been successfully loaded.'))
        
      }
    }
      else{
      # print("line39")
      # print(package)
      library(package,character.only=TRUE)#Already installed globally so load globally
      print(paste0('package ', package2use[pk], ' has been successfully loaded.'))
        
    }
  }
}
temp <- c('a','b')
a <- NULL
paste(temp, collapse = '')


