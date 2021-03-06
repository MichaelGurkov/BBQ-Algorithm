import.gdp.data = function(filepath){
  
  gdp = read.csv(filepath)
  
  gdp$Date = gsub(pattern = "Q",replacement = "",
                  x = levels(gdp$Date)[gdp$Date],fixed = TRUE)
  
  gdp$Date = as.yearqtr(gdp$Date, format = "%Y-%q")
  
  gdp = xts(x = gdp$GDP, order.by = gdp$Date)
  
  return(gdp)
  
}

identify.turning.point = function(window){
  
  pos = ceiling(length(window) / 2)
  
  if (window[pos] == max(window)) {
    
    return(1)
    
  } else if (window[pos] == min(window)) {
    
    return(-1)
    
  } else {
    
    return(0)
  }
  
}

get.extreme.point = function(points,start_period,end_period,
                             peaks = TRUE){
  
  sub_points = points[index(points) >= start_period & index(points) <= end_period,]
  
  if (length(sub_points) == 0){return(NULL)}
  
  if (peaks) {
    
    return(sub_points[sub_points[,1] == max(sub_points[,1]),])
    
  } else {
    
    return(sub_points[sub_points[,1] == min(sub_points[,1]),])
    
  }
  
}

get.alternating.peaks = function(peaks, troughs, timeframe){
  
  start_points = index(troughs)
  
  end_points = c(index(troughs)[-1],timeframe[length(timeframe)])
  
  points = cbind.data.frame(start_points,
                       end_points)
  
  names(points) = c("Start_Point","End_Point")
  
  alt.peaks = apply(points, 1,
                    function(Z,peaks){get.extreme.point(Z[1],Z[2],
                                                   points = peaks)},
                    peaks = peaks)
  
  alt.peaks = do.call(rbind.xts,alt.peaks)
  
}

get.alternating.troughs = function(peaks, troughs, timeframe){
  
  start_points = index(peaks)
  
  end_points = c(index(peaks)[-1],timeframe[length(timeframe)])
  
  points = cbind.data.frame(start_points,
                            end_points)
  
  names(points) = c("Start_Point","End_Point")
  
  alt.troughs = apply(points, 1,
                    function(Z,troughs){get.extreme.point(Z[1],Z[2],
                                                        points = troughs)},
                    troughs = troughs)
  
  alt.troughs = do.call(rbind.xts,alt.troughs)
  
}

# Censoring rules

get.phase.censored.points = function(peaks,troughs, min_phase_length){
  
  tp_df = rbind.xts(peaks, troughs)
  
  short_phase_ind = which(diff(index(tp_df)) * 4 < min_phase_length)
  
  censor_ind = index(tp_df)[unique(c(short_phase_ind, short_phase_ind + 1))]
  
  censored_tp_df = tp_df[!index(tp_df) %in% censor_ind,]
  
  if (length(censored_tp_df > 0)){
  
    censored_peaks = censored_tp_df[censored_tp_df$TP == 1,]
  
  
    censored_troughs = censored_tp_df[censored_tp_df$TP == -1,]
    
    return(list(censored_peaks = censored_peaks,
                censored_troughs = censored_troughs))
  
  } else {
    
  return(list(censored_peaks = NULL,
         censored_troughs = NULL))
    
  }

}

get.cycle.censored.points = function(peaks,troughs, min_cycle_length){
  
  tp_df = rbind.xts(peaks, troughs)
  
  short_cycle_ind_peaks = which(diff(index(peaks)) * 4 < min_cycle_length)
  
  short_cycle_ind_troughs = which(diff(index(troughs)) * 4 < min_cycle_length)
  
  censor_ind = index(tp_df)[unique(c(short_cycle_ind_peaks,
                                     short_cycle_ind_peaks + 1,
                                     short_cycle_ind_troughs,
                                     short_cycle_ind_troughs+1))]
  
  censored_tp_df = tp_df[!index(tp_df) %in% censor_ind,]
  
  if (length(censored_tp_df > 0)){
    
    censored_peaks = censored_tp_df[censored_tp_df$TP == 1,]
    
    
    censored_troughs = censored_tp_df[censored_tp_df$TP == -1,]
    
    return(list(censored_peaks = censored_peaks,
                censored_troughs = censored_troughs))
    
  } else {
    
    return(list(censored_peaks = NULL,
                censored_troughs = NULL))
    
  }
  
}



# Approximation to BBQ algorithm

get.peaks.bbq.approx = function(window){
  
  pos = ceiling(length(window) / 2)
  
  if (window[pos] == max(window)) {
    
    return(1)
  
  } else {
    
    return(0)
    
  }
}

get.troughs.bbq.approx = function(window){
  
  pos = ceiling(length(window) / 2)
  
  if (window[pos] == min(window)) {
    
    return(-1)
    
  } else {
    
    return(0)
    
  }
}

add.cycle.state.bbq.approx = function(df){
  
  df$State = 0
  
  df$State[1] = df$State[2] = ifelse(min(index(df)[!df$peaks == 0]) < 
                 min(index(df)[!df$troughs == 0]),1,0)
  
  for (rownum in 3:nrow(df)){
    
    t1 = rownum - 1
    
    t2 = rownum - 2
    
    df$State[rownum] = coredata(df$State[t1]) * (1 - coredata(df$State[t2])) + 
                       coredata(df$State[t1]) * coredata(df$State[t2]) * (1 - coredata(df$peaks[t1])) + 
                       (1 - coredata(df$State[t1])) * (1 - coredata(df$State[t2])) * coredata(df$troughs[t1])
    
   }
  
  return(df) 
  
  
}



