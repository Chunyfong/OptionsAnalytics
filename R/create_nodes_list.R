#' Create named list of market nodes
#'
#' @param node_id ID of the market node
#' @param recursive Logical indicating whether to traverse the market hierarchy or not (default)
#'
#' @return Named list where the node_ids constitute the values
#'
#' @importFrom purrr set_names
#' @examples
create_nodes_list <- function(node_id, recursive = FALSE) {
  if (!recursive) {
    mkts <- request_market_navigation(node_id)

    return(purrr::set_names(map(mkts$nodes, "id"), map(mkts$nodes, "name")))
  } else {
    mkts <- traverse_market_hierarchy(node_id)

    return(purrr::set_names(mkts$epic, mkts$instrumentName))
  }
}
