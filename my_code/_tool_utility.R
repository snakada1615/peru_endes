#' --------------------------------
#' @title getYesNo
#' @description
#' Yes/Noの選択肢を表示する関数
#' @param mes メッセージ
#' @return TRUE/FALSE
#' --------------------------------
getYesNo <- function(mes) {
  repeat {
    ans <- menu(c("Yes", "No"), title = mes)
    if (ans == 1) {
      return(TRUE)
    } else if (ans == 2) {
      return(FALSE)
    }
  }
}
