#' Plot option Profit and Loss Scenarios
#'
#' @param strategy Strategy object
#'
#' @return Plot of PnL
#' @export
#'
#' @examples
plot_strategy_pnl <- function(strategy, underlyer_margin = 40) {
  strikes <- purrr::map_int(strategy$legs, "strike_price")

  strike_min <- min(strikes)

  strike_max <- max(strikes)

  pnls <- purrr::map(strategy$legs,
                     ~compute_option_pnl(.,underlyer_prices = strategy$underlyer_prices$close,
                                                        underlyer_min = strike_min,
                                                        underlyer_max = strike_max,
                                                        underlyer_margin))

  opening_prices <- purrr::map(strategy$legs, "opening_price")

  positions <- purrr::map(strategy$legs, "position")

  pnl_scen <- purrr::pmap(
    list(pnls, opening_prices, positions),
    ~ (..1 - ..2) * ..3
  ) %>% purrr::reduce(`+`)

  AUC <- pracma::trapz(as.numeric(rownames(pnl_scen)),pnl_scen[,1]) %>% round()

  pos <- which(pnl_scen>0)

  start_pos <- min(pos)

  inter_min <- approx(row.names(pnl_scen)[(start_pos-1):start_pos] , pnl_scen[(start_pos-1):start_pos])

  min_brkeven <- inter_min$x[which.min(abs(inter_min$y))] %>% round(2)

  end_pos <- max(pos)

  inter_max <- approx(row.names(pnl_scen)[end_pos:(end_pos+1)] , pnl_scen[end_pos:(end_pos+1)])

  max_brkeven <- inter_max$x[which.min(abs(inter_max$y))] %>% round(2)

  annotation <- glue::glue("AUC:{AUC}")

  underlyer <- rownames(pnl_scen)

  max_profit <- max(pnl_scen)

  plotly::plot_ly() %>%
    plotly::add_trace(x = underlyer,
                      y = pnl_scen[,1],
                      type = "scatter",
                      mode = "lines+markers") %>%
    plotly::add_text(x = as.numeric(min(underlyer)),
                     y = max_profit,
                     text = annotation) %>%
    plotly::add_segments(x = min_brkeven,
                         xend = min_brkeven,
                         y = 0,
                         yend = max_profit,
                         color = I("grey")) %>%
    plotly::add_segments(x = max_brkeven, xend = max_brkeven, y = 0, yend = max_profit, color = I("grey"))
}

#' Compute option PnL Scenarios at expiry
#'
#' @param option_leg Option Leg object
#' @param underlyer_prices Vector of underlyer closing prices
#' @param underlyer_min Minimum underlyer price to compute profit on
#' @param underlyer_max Maximum underlyer price to compute profit on
#' @param underlyer_margin Additional padding at ends of pnl chart
#'
#' @return
#'
#' @examples
compute_option_pnl <- function(option_leg,
                                     underlyer_prices,
                                     underlyer_min,
                                     underlyer_max,
                                     underlyer_margin = 20
                                     ) {



  partial_options <- purrr::partial(fOptions::GBSOption,
                                    TypeFlag = tolower(option_leg$option_type),
                                    X = option_leg$strike_price,
                                    Time = 0,
                                    r = 0.05,
                                    b = 0.05,
                                    sigma = 0.1
  )

  underlyer_space <- seq(underlyer_min-underlyer_margin, underlyer_max+underlyer_margin, 5)

  option_scenarios <- purrr::map_dbl(underlyer_space, ~ partial_options(S = .) %>% slot("price"))

  option_scenarios[is.nan(option_scenarios)] <- 0

  matrix(
    data = option_scenarios,
    nrow = length(underlyer_space),
    ncol = 1, dimnames = list(underlyer_space, "profit")
  )

}