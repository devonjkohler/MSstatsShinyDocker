######### UI #########

# choices of groups for contrast matrix

choices <- reactive({
  if(input$DDA_DIA=="TMT"){
    levels(preprocess_data()$ProteinLevelData$Condition)
    
  }
  else{
    levels(preprocess_data()$ProteinLevelData$GROUP)
  }
  
})
row <- reactive({rep(0, length(choices()))})
contrast <- reactiveValues()
comp_list <- reactiveValues()
significant <- reactiveValues()


observe({
  if(input$DDA_DIA == "TMT"){
    shinyjs::hide("Design")
  }
  else{
    shinyjs::show("Design")
  }
})

output$choice1 <- renderUI({
  selectInput("group1", "Group 1", choices())
})

output$choice2 <- renderUI({
  selectInput("group2", "Group 2", choices())
})

output$choice3 <- renderUI({
  selectInput("group3", "", choices())
})

output$comp_name <- renderUI({
  textInput("comp_name", label = "Comparison Name", value = "")
})

output$weights <- renderUI({
  
  lapply(1:length(choices()), function(i) {
    list(
      numericInput(paste0("weight", i), label = choices()[i], value=0))  
  })
})

# rownames for matrix

Rownames <- eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  tryCatch({
    rownames(matrix_build())},
    error=function(e){})
})

# choices of comparisons/proteins to plot

output$WhichComp <- renderUI ({
  selectInput("whichComp", 
              label = h5("Select comparison to plot"), c("all", Rownames()), selected = "all")
})

output$WhichProt <- renderUI ({
  selectInput("whichProt",
                 label = h4("which protein to plot"), unique(get_data()[[1]]))
})

output$WhichProt1 <- renderUI ({
  selectizeInput("whichProt1",
                 label = h4("which protein to plot"), c("", unique(get_data()[[1]])))
})


########## functions ########

# build matrix

observeEvent(input$def_comp, {
  contrast$matrix <- NULL
  comp_list$dList <- NULL
})

observeEvent(input$proceed1, {
  contrast$matrix <- NULL
  comp_list$dList <- NULL
  significant$result <- NULL
})

## Check contrast matrix was created correctly
check_cond <- eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  if(input$def_comp == "custom") {
    validate(
      need(input$group1 != input$group2, "Please select different groups")
    )}
  
  else if(input$def_comp == "custom_np") {
    
    wt_sum <- 0
    for (index in 1:length(choices())){
      wt_sum <- wt_sum + input[[paste0("weight", index)]]
    }
    
    validate(
      need( wt_sum == 0, 
            "The contrast weights should sum up to 0")
    )}
})

matrix_build <- eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  if(input$def_comp == "custom") {
    if(input$group1 == input$group2){
      return(contrast$matrix)
    }
    index1 <- reactive({which(choices() == input$group1)})
    index2 <- reactive({which(choices() == input$group2)})
    comp_list$dList <- unique(c(isolate(comp_list$dList), paste(input$group1, "vs", 
                                                                input$group2, sep = " ")))
    contrast$row <- matrix(row(), nrow=1)
    contrast$row[index1()] = 1
    contrast$row[index2()] = -1
    if (is.null(contrast$matrix)) {
      contrast$matrix <- contrast$row 
    } 
    else {
      contrast$matrix <- rbind(contrast$matrix, contrast$row)
      contrast$matrix <- rbind(contrast$matrix[!duplicated(contrast$matrix),])
    }
    print(contrast$matrix)
    rownames(contrast$matrix) <- comp_list$dList
    colnames(contrast$matrix) <- choices()
  }
  
  else if(input$def_comp == "custom_np") {
    
    wt_sum <- 0
    for (index in 1:length(choices())){
      wt_sum <- wt_sum + input[[paste0("weight", index)]]
    }
    
    if(wt_sum != 0){
      return(contrast$matrix)
    }
    
    comp_list$dList <- unique(c(isolate(comp_list$dList), input$comp_name))
    contrast$row <- matrix(row(), nrow=1)
    
    for (index in 1:length(choices())){
      contrast$row[index] = input[[paste0("weight", index)]]
    }
    
    if (is.null(contrast$matrix)) {
      contrast$matrix <- contrast$row 
    } else {
      contrast$matrix <- rbind(contrast$matrix, contrast$row)
      contrast$matrix <- rbind(contrast$matrix[!duplicated(contrast$matrix),])
    }
    print(contrast$matrix)
    rownames(contrast$matrix) <- comp_list$dList
    colnames(contrast$matrix) <- choices()
  }
  
  else if (input$def_comp == "all_one") {
    print(choices())
    for (index in 1:length(choices())) {
      index3 <- reactive({which(choices() == input$group3)})
      if(index == index3()) next
      if(input$DDA_DIA=="TMT"){
        comp_list$dList <- c(isolate(comp_list$dList), 
                             paste(choices()[index], " vs ", 
                                   input$group3, sep = ""))
      } else{
        comp_list$dList <- c(isolate(comp_list$dList), 
                             paste(choices()[index], " vs ", 
                                   input$group3, sep = ""))
      }
      
      contrast$row <- matrix(row(), nrow=1)
      contrast$row[index] = 1
      contrast$row[index3()] = -1
      if (is.null(contrast$matrix)) {
        contrast$matrix <- contrast$row 
      } else {
        contrast$matrix <- rbind(contrast$matrix, contrast$row)
      }
      rownames(contrast$matrix) <- comp_list$dList
      colnames(contrast$matrix) <- choices()
    }
  }
  else if (input$def_comp == "all_pair") {
    contrast$matrix <- NULL
    for (index in 1:length(choices())) {
      for (index1 in 1:length(choices())) {
        if (index == index1) next
        if (index < index1) {
          if(input$DDA_DIA=="TMT"){
            comp_list$dList <- c(isolate(comp_list$dList), 
                                 paste(choices()[index], " vs ", 
                                       choices()[index1], sep = ""))
          } else{
            comp_list$dList <- c(isolate(comp_list$dList), 
                                 paste(choices()[index], " vs ", 
                                       choices()[index1], sep = ""))
          }
          contrast$row <- matrix(row(), nrow=1)
          contrast$row[index] = 1
          contrast$row[index1] = -1
          if (is.null(contrast$matrix)) {
            contrast$matrix <- contrast$row 
          } else {
            contrast$matrix <- rbind(contrast$matrix, contrast$row)
            contrast$matrix <- rbind(contrast$matrix[!duplicated(contrast$matrix),])
          }
          rownames(contrast$matrix) <- comp_list$dList
          colnames(contrast$matrix) <- choices()
        }
      }
    }
  }
  shinyjs::enable("calculate")
  return(contrast$matrix)
})

# clear matrix

observeEvent({input$clear | input$clear1 | input$clear2 | input$clear3},  {
  shinyjs::disable("calculate")
  comp_list$dList <- NULL
  contrast$matrix <- NULL
})

# Run Models
## Function for LF so we can track progress
lf_model = function(data, contrast.matrix, busy_indicator = TRUE){
  
  proteins = as.character(unique(data$ProteinLevelData[, 'Protein']))
  
  if (busy_indicator){
    show_modal_progress_line() # show the modal window
    
    ## Setup progress bar
    update_val = 1/length(proteins)
    counter = 0
  }
  
  ## Prepare data for modeling
  labeled = data.table::uniqueN(data$FeatureLevelData$Label) > 1
  split_summarized = MSstatsPrepareForGroupComparison(data)
  repeated = checkRepeatedDesign(data)
  samples_info = getSamplesInfo(data)
  groups = unique(data$ProteinLevelData$GROUP)
  contrast_matrix = MSstatsContrastMatrix(contrast.matrix, groups)
  
  ## Inside MSstatsGroupComparison function
  groups = sort(colnames(contrast_matrix))
  has_imputed = attr(split_summarized, "has_imputed")
  all_proteins_id = seq_along(split_summarized)
  test_results = vector("list", length(all_proteins_id))
  pb = txtProgressBar(max = length(all_proteins_id), style = 3)
  
  for (i in all_proteins_id) {
    comparison_outputs = MSstatsGroupComparisonSingleProtein(
      split_summarized[[i]], contrast_matrix, repeated, 
      groups, samples_info, TRUE, has_imputed
    )
    test_results[[i]] = comparison_outputs
    
    ## Update progress bar
    if (busy_indicator){
      counter = counter + update_val
      update_modal_progress(counter)
    }
  }
  
  results = MSstatsGroupComparisonOutput(test_results, data, 2) ## 2 is log_base param
  
  if (busy_indicator){
    remove_modal_progress() # remove it when done
  }
  
  return(results)
  
}

tmt_model = function(data, contrast.matrix, busy_indicator = TRUE){
  
  proteins = as.character(unique(data$ProteinLevelData[, 'Protein']))
  
  if (busy_indicator){
    show_modal_progress_line() # show the modal window
    
    ## Setup progress bar
    update_val = 1/length(proteins)
    counter = 0
  }
  
  ## Prep data for modeling
  summarized = MSstatsTMT:::MSstatsPrepareForGroupComparisonTMT(data$ProteinLevelData, 
                                                                TRUE,#remove_norm_channel
                                                                TRUE)#remove_empty_channel
  contrast_matrix = MSstats::MSstatsContrastMatrix(contrast.matrix,
                                                   unique(summarized$Group))
  fitted_models = MSstatsTMT:::MSstatsFitComparisonModelsTMT(summarized)
  FittedModel <- fitted_models$fitted_model
  names(FittedModel) <- fitted_models$protein
  
  fitted_models = MSstatsTMT:::MSstatsModerateTTest(summarized, fitted_models, 
                                                    input$moderated)#moderated
  
  testing_results = vector("list", length(fitted_models))
  
  for (i in seq_along(fitted_models)) {
    testing_result = MSstatsTMT:::MSstatsTestSingleProteinTMT(fitted_models[[i]], 
                                                              contrast_matrix)
    testing_results[[i]] = testing_result
    
    ## Update progress bar
    if (busy_indicator){
      counter = counter + update_val
      update_modal_progress(counter)
    }
  }
  
  testing_results = MSstatsTMT:::MSstatsGroupComparisonOutputTMT(
    testing_results, "BH") #adj.method
  
  results = list(ComparisonResult = testing_results, 
                 ModelQC = NULL,
                 FittedModel = FittedModel)   
  
  if (busy_indicator){
    remove_modal_progress() # remove it when done
  }
  
  return(results)
  
}

data_comparison <- eventReactive(input$calculate, {
  
  input_data = preprocess_data()
  contrast.matrix = matrix_build()
  
  print(matrix_build())
  if(input$DDA_DIA=="TMT"){
    model <- tmt_model(input_data, contrast.matrix)
  }
  else{
    model <- lf_model(input_data, contrast.matrix)
  }
  
  return(model)
})

data_comparison_code <- eventReactive(input$calculate, { 
  
  codes <- preprocess_data_code()
  
  if(input$DDA_DIA == "TMT"){
    
    comp.mat <- matrix_build()
    
    codes <- paste(codes, "\n# Create the contrast matrix\n", sep = "")
    codes <- paste(codes, "contrast.matrix <- NULL\n", sep = "")
    for(i in 1:nrow(comp.mat)){
      codes <- paste(codes, "comparison <- matrix(c(", toString(comp.mat[i,]),"),nrow=1)\n", sep = "")
      codes <- paste(codes, "contrast.matrix <- rbind(contrast.matrix, comparison)\n", sep = "")
      
    }
    
    codes <- paste(codes, "row.names(contrast.matrix)<-c(\"", paste(row.names(comp.mat), collapse='","'),"\")\n", sep = "")
    codes <- paste(codes, "colnames(contrast.matrix)<-c(\"", paste(colnames(comp.mat), collapse='","'),"\")\n", sep = "")

    codes <- paste(codes, "\n# Model-based comparison\n", sep = "")
    codes <- paste(codes,"model <- MSstatsTMT:::groupComparisonTMT(summarized,
                   contrast.matrix = contrast.matrix,
                   moderated = ", input$moderated,",\t\t\t\t   
                   adj.method = \"BH\",
                   remove_norm_channel = TRUE,
                   remove_empty_channel = TRUE
                   )\n", sep = "")
  }
  else{
    comp.mat <- matrix_build()
    codes <- paste(codes, "\n# Create the contrat matrix\n", sep = "")
    codes <- paste(codes, "contrast.matrix <- NULL\n", sep = "")
    for(i in 1:nrow(comp.mat)){
      codes <- paste(codes, "comparison <- matrix(c(", toString(comp.mat[i,]),"),nrow=1)\n", sep = "")
      codes <- paste(codes, "contrast.matrix <- rbind(contrast.matrix, comparison)\n", sep = "")
      
    }
    
    codes <- paste(codes, "row.names(contrast.matrix)<-c(\"", paste(row.names(comp.mat), collapse='","'),"\")\n", sep = "")
    codes <- paste(codes, "colnames(contrast.matrix)<-c(\"", paste(colnames(comp.mat), collapse='","'),"\")\n", sep = "")
    
    codes <- paste(codes, "\n# Model-based comparison\n", sep = "")
    codes <- paste(codes,"model <- MSstats:::groupComparison(contrast.matrix, summarized)\n", sep = "")
  }
  
  codes <- paste(codes, "groupComparisonPlots(data=model$ComparisonResult,
                         type=\"Enter VolcanoPlot, Heatmap, or ComparisonPlot\",
                         which.Comparison=\"all\",
                         which.Protein=\"all\",
                         address=\"\")\n", sep="")
  
  return(codes)
})


round_df <- function(df) {
  nums <- vapply(df, is.numeric, FUN.VALUE = logical(1))
  
  df[,nums] <- round(df[,nums], digits = 4)
  
  (df)
}

SignificantProteins <- eventReactive(input$calculate,{
  if(input$DDA_DIA=="TMT"){
    data_comp <- data_comparison()
    significant$result <- data_comp$ComparisonResult[
      (data_comp$ComparisonResult$adj.pvalue < input$signif) & 
        (!is.na(data_comp$ComparisonResult$adj.pvalue)), ]
    
  } else {
    significant$result <- with(data_comparison(),
                               round_df(ComparisonResult[
                                 (ComparisonResult$adj.pvalue < input$signif) & 
                                   (!is.na(ComparisonResult$adj.pvalue)), ]))
  }
  return(significant$result)
})

# comparison plots

# observeEvent(input$plotresults, {
#   if(input$typeplot != "ComparisonPlot") {
#     group_comparison(TRUE)
#   }
#   else {
#     group_comparison(TRUE)
#   }
# })
# 
# observeEvent(input$viewresults, {
#   if(input$typeplot != "ComparisonPlot") {
#     group_comparison(TRUE)
#   }
#   else {
#     group_comparison(TRUE)
#   } 
# })

group_comparison <- function(saveFile1, pdf) {
  
  id1 <- as.character(UUIDgenerate(FALSE))
  id_address1 <- paste("tmp/",id1, sep = "")
  path1 <- function() {
    if (saveFile1) {
      path1_id = paste("www/", id_address1, sep = "")
    }
    else {
      path1_id = FALSE
    }
    return(path1_id)
  }
  
  if(input$DDA_DIA=="TMT"){
    
    plot1 <- groupComparisonPlots2(data=data_comparison()$ComparisonResult,
                                   type=input$typeplot,
                                   sig=input$sig,
                                   FCcutoff=input$FC,
                                   logBase.pvalue=input$logp,
                                   ProteinName=input$pname,
                                   numProtein=input$nump, 
                                   clustering=input$cluster, 
                                   which.Comparison=input$whichComp,
                                   which.Protein = input$whichProt,
                                   address=path1(),
                                   savePDF=pdf
    )
    
  } else{
    
    plot1 <- groupComparisonPlots2(data=data_comparison()$ComparisonResult,
                                   type=input$typeplot,
                                   sig=input$sig,
                                   FCcutoff=input$FC,
                                   logBase.pvalue=input$logp,
                                   ProteinName=input$pname,
                                   numProtein=input$nump, 
                                   clustering=input$cluster, 
                                   which.Comparison=input$whichComp,
                                   which.Protein = input$whichProt,
                                   address=path1(),
                                   savePDF=pdf
    )
    
  }
  
  if(saveFile1) {
    return(id_address1)
  }
  else {
    return(plot1)
  }
}

# model assumptions plots

assumptions1 <- function(saveFile3, protein) {
  if (input$whichProt1 != "") {
    id2 <- as.character(UUIDgenerate(FALSE))
    id_address2 <- paste("tmp/",id2, sep = "")
    path2 <- function()  {
      if (saveFile3) {
        path_id2 = paste("www/", id_address2, sep = "")
      } 
      else {
        path_id2 = FALSE
      }
      return (path_id2)
    }
    
    plots <- modelBasedQCPlots(data=data_comparison(), type=input$assum_type, 
                               which.Protein = protein, address = path2())
    
    if(saveFile3) {
      return(id_address2)
    }
    else {
      return(plots)
    }
  }
  else {
    return(NULL)
  }
}



########## output ##########

# download comparison data

output$compar <- downloadHandler(
  filename = function() {
    paste("comparison-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ComparisonResult, file)
  })

output$model_QC <- downloadHandler(
  filename = function() {
    paste("ModelQC-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ModelQC, file)
  })

output$fitted_v <- downloadHandler(
  filename = function() {
    paste("model_summary-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(capture.output(data_comparison()$fittedmodel), file)
  })

# matrix

output$message <- renderText({
  check_cond()
})
observeEvent(input$calculate, {output$code.button <- renderUI(
  downloadButton("download_code", "Download analysis code", icon("download"),
    style="color: #000000; background-color: #75ba82; border-color: #000000"))})

output$matrix <- renderUI({
  tagList(
    h2("Comparison matrix"),
    br(),
    textOutput("message"),
    br(),
    if (is.null(contrast$matrix)) {
      ""
    } else {
      dataTableOutput("table") 
    }
  )
})

output$table <-  renderDataTable({
  matrix_build()
}, rownames = T)

# table of significant proteins

output$table_results <- renderUI({
  req(data_comparison())
  req(SignificantProteins())
  if (is.null(significant$result)) {

    tagList(
      tags$br())
  } else {
    tagList(
      tags$br(),
      h2("Results"),
      h5("There are ",textOutput("number", inline = TRUE),"significant proteins"),
      tags$br(),
      dataTableOutput("significant"),
      downloadButton("download_compar", "Download all modeling results"),
      downloadButton("download_signif", "Download significant proteins")
      
    )
    
  }
  
})

output$significant <- renderDataTable({
  SignificantProteins()
}, rownames = F
)

# number of significant proteins

output$number <- renderText({
  nrow(SignificantProteins())
})

# plot in browser 

observeEvent(input$typeplot, {
  updateSelectInput(session, "whichComp", selected = "all")
})

observeEvent(input$viewresults, {
  insertUI(
    selector = "#comparison_plots",
    ui=tags$div(
      plotOutput("comp_plots", height = "100%", click = "click1"),
      conditionalPanel(condition = "input.typeplot == 'VolcanoPlot' && input.DDA_DIA!='TMT'",
                       h5("Click on plot for details"),
                       verbatimTextOutput("info2")),
      conditionalPanel(condition = "input.typeplot == 'Heatmap'",
                       sliderInput("height", "Plot height", value = 500, min = 200, max = 1300, post = "px"))
    )
  )
}
)

observe ({output$comp_plots <- renderPlot({
  group_comparison(FALSE, FALSE)}, height = input$height
)
})

plotset <- reactive({
  
  if(input$DDA_DIA=="TMT"){
    data_comp <- data_comparison()$ComparisonResult
    v1 <- data_comp[,1]
    v2 <- round(data_comp[,3], 10)
    v3 <- round(data_comp[,8], 10)
    v4 <- data_comp[,2]
    
  } else{
    v1 <- data_comparison()$ComparisonResult[,1]
    v2 <- round(data_comparison()$ComparisonResult[,3], 10)
    v3 <- round(data_comparison()$ComparisonResult[,8], 10)
    v4 <- data_comparison()$ComparisonResult[,2]
    
  }
  
  if (input$logp == "2") {
    v3 <- -log2(v3)
  }
  else if (input$logp == "10") {
    v3 <- - log10(v3)
  }
  
  df <- data.frame(v1,v2,v3,v4)
  df <- df[df$v4 == input$whichComp,]
  colnames(df) <- c("Protein", "logFC", "logadj.pvalue", "comparison")
  return(df)
})

output$info2 <- renderPrint({
  print(nearPoints(plotset(), input$click1, xvar = "logFC", yvar = "logadj.pvalue"))
})

# Assumption plots in browser

output$verify <- renderUI ({
  tagList(
    plotOutput("assum_plots", width = "800px", height = "600px"),
    conditionalPanel(condition = "input.whichProt1 != ''",
                     actionButton("saveone1", "Save this plot"),
                     bsTooltip(id = "saveone1", title = "Open plot as pdf.  Popups must be enabled", placement = "bottom", trigger = "hover"),
                     actionButton("saveall1", "Save all plots"),
                     bsTooltip(id = "saveall1", title = "Open pdf of all plots.  Popups must be enabled", placement = "bottom", trigger = "hover")
    )
  )
})

output$assum_plots <- renderPlot({
  assumptions1(FALSE, input$whichProt1)})


# downloads
observeEvent(input$saveone1, {
  path <- assumptions1(TRUE, input$whichProt1)
  if (input$assum_type == "QQPlots") {
    js <- paste("window.open('", path, "QQPlot.pdf')", sep="")
    shinyjs::runjs(js);
  }
  else if (input$type == "ResidualPlots") {
    js <- paste("window.open('", path, "ResidualPlots.pdf')", sep="")
    shinyjs::runjs(js);
  }
})

observeEvent(input$saveall1, {
  path <- assumptions1(TRUE, "all")
  if (input$assum_type == "QQPlots") {
    js <- paste("window.open('", path, "QQPlot.pdf')", sep="")
    shinyjs::runjs(js);
  }
  else if (input$type == "ResidualPlots") {
    js <- paste("window.open('", path, "ResidualPlots.pdf')", sep="")
    shinyjs::runjs(js);
  }
})


output$download_compar <- downloadHandler(
  filename = function() {
    paste("test_result-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ComparisonResult, file)
    
  }
)

output$download_code <- downloadHandler(
  filename = function() {
    paste("mstats-code-", Sys.Date(), ".R", sep="")
  },
  content = function(file) {
    writeLines(paste(
                  data_comparison_code(), sep = ""), file)
  })

output$download_signif <- downloadHandler(
  filename = function() {
    paste("data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(SignificantProteins(), file)
  }
)

observeEvent(input$plotresults, {
  insertUI(
    selector = "#comparison_plots",
    ui=tags$div(
      if (input$typeplot == "VolcanoPlot") {
        js <- paste("window.open('", group_comparison(TRUE, TRUE), "VolcanoPlot.pdf')", sep="")
        shinyjs::runjs(js);
      }
      else if (input$typeplot == "Heatmap") {
        js <- paste("window.open('", group_comparison(TRUE, TRUE), "Heatmap.pdf')", sep="")
        shinyjs::runjs(js);
      }
      else if (input$typeplot == "ComparisonPlot") {
        js <- paste("window.open('", group_comparison(TRUE, TRUE), "ComparisonPlot.pdf')", sep="")
        shinyjs::runjs(js);
      }
    )
  )
})


observeEvent(input$calculate,{
  shinyjs::enable("Design")
  shinyjs::enable("typeplot")
  shinyjs::enable("WhichComp")
  shinyjs::enable("download_code")
  
})


# observeEvent(input$power_next, {
#   updateTabsetPanel(session = session, inputId = "tablist", selected = "Future")
# })
