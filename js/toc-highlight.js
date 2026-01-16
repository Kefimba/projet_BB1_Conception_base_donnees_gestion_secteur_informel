// JS to ensure TOC highlights the active section on click and on scroll
(function(){
  function throttle(fn, wait){
    var last = 0; var t;
    return function(){
      var now = Date.now();
      if (now - last >= wait){ last = now; fn(); }
      else { clearTimeout(t); t = setTimeout(fn, wait); }
    };
  }

  function findTocLinks(){
    return Array.from(document.querySelectorAll('.summary a, .book-summary a, nav.summary a, .toc a'));
  }

  function clearActive(links){ links.forEach(function(a){ a.classList.remove('active'); }); }

  function matchLinkForId(links, id){
    if(!id) return null;
    // try exact match, and match with ./ and full path
    for(var i=0;i<links.length;i++){
      var href = links[i].getAttribute('href') || '';
      if(href === id) return links[i];
      if(href === id.replace(/^\/#/, '#')) return links[i];
      if(href.endsWith(id)) return links[i];
      try{ if(decodeURIComponent(href) === id) return links[i]; }catch(e){}
    }
    return null;
  }

  function collectHeads(){
    return Array.from(document.querySelectorAll('h1[id], h2[id], h3[id], h4[id]')).map(function(h){
      return {id: '#'+h.id, top: h.getBoundingClientRect().top + window.pageYOffset};
    });
  }

  function onReady(){
    var links = findTocLinks();
    if(!links.length) return;

    // click handlers
    links.forEach(function(a){
      a.addEventListener('click', function(){
        clearActive(links);
        this.classList.add('active');
      }, {passive:true});
    });

    // scroll handler
    var heads = collectHeads();
    var onScroll = throttle(function(){
      heads = collectHeads();
      var fromTop = window.pageYOffset + 20;
      var current = null;
      for(var i=0;i<heads.length;i++){
        if(heads[i].top <= fromTop) current = heads[i];
      }
      if(current){
        var link = matchLinkForId(links, current.id);
        if(link){ clearActive(links); link.classList.add('active'); }
      }
    }, 120);

    window.addEventListener('scroll', onScroll, {passive:true});
    window.addEventListener('hashchange', function(){
      var link = matchLinkForId(links, window.location.hash);
      if(link){ clearActive(links); link.classList.add('active'); }
    });

    // initial highlight based on hash
    if(window.location.hash){
      var l = matchLinkForId(links, window.location.hash);
      if(l){ clearActive(links); l.classList.add('active'); }
    }
  }

  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', onReady);
  else onReady();
})();
