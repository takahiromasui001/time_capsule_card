module CardsHelper
  def card_tabs
    [
      { key: 'scheduled', label: '投函済み', path: cards_scheduled_index_path },
      { key: 'arrived', label: '到着済み', path: cards_arrived_index_path },
      { key: 'done', label: '完了', path: cards_done_index_path }
    ]
  end
end
