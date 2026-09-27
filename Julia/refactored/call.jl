function checkCond2(a::Int64, m1::Int64, m2::Int64, b::Int64, isWhole::Bool, _view::SubArray) #is there a way to convert view to arr
    if isWhole == true
        #m region
        #compare content (of 3-Fractal: a, m, b )

        compareTriad(a, m1, b, _view) #ok #issue: arr [should be view ] #hillarious : was b1 instead of b    #compareTriad(..,_view)

        #Do:
        #view1 = view(arr, a:m1) #correct result
        #view2 = view(arr, m1:b) #unneeded
        #effect(a, m1, _view) #  effect(a, m, view(,a,b))  isStop(1, 2, view([1, 2], 1:2))
        #effect(m1, b, view2) #<---------- # 3:5
        #to go left: fix a, decrease b #but we start with a:m1 - interval is verified
        # newView = view(_view, a:m1)
        println("a = ", a, " m1= ", m1, " newView = ", newView)

        goleft!(a, m1, newView) #using subview  #was a,m1 #<----- then here (first left I see a:m1 the same i.e )

        #remap required
        m1, b = remap(m1, b)
        print("m1, b = ", m1, b)

        # view2 = view(_view, m1:b) #issue: building proper view - subarray of an array #was m1,b
        # effect(m1, b, view(_view, m1:b)) #isStoppingCondition() #TODO: requires: currentValue
        return m1, b, isWhole
    elseif isWhole == false
        #check bounds  compare content: (of 4-Fractal: a,m1,m2,b )
        #2 middles become one  a ... m1 nc, m1 m2 =1 (n/A) m2 b1
        #should be                  m1  nc, d(m1 m2)=0 m1-m2=0  (m2 loses its previous position to become 1 with m1 )
        # 5 6   7 8 9
        # (5 6) 7 8 9 #  [-1 ]
        #5 nc 6 7 8
        #2. length -= 1
        # remapForm1m2

        compareQuartet(a, m1, m2, b, _view) #compare arr values at 4 index points: a,m1,m2,b  #ok
        #view1 = view(arr, a:m1) #correct result
        #Index changes: need for Remapping: m2, b
        #b- m2 #difference
        #the fix for the following view:
        m2, b = remap(m2, b) #done
        #adjust index for merging m1m2 step:
        #m2 -= 1
        #b -= 1
        # b = euclidDist(m2, b) #+1
        # m2 = 1
        #  view2 = view(_view, m2:b) #issue: building proper view - subarray of an array  #<----------------error  #was m2,b
        #TODO: handle interval m1,m2 as well (for completeness: we got to compare all vertex intervals )


        #effect(a, m1, view1) #  effect(a, m, view(,a,b))  isStop(1, 2, view([1, 2], 1:2))
        #effect(m2, b, view2) #<---------- # 3:5

        #  goleft!(view(_view, a:m1)) #go left iteratively # Redundant
        #  goright!(view2) # goright!(m2, b, view(view2, m2:b)) #go right iteratively #<---------

        # effect(m2, b, view(_view, m2:b))
        return m2, b, isWhole
    end
end

#---

@inline function swapContent(aContent, bContent, _view::SubstitutionString) # ; offset=1) #new! # a,b,indicies in arr  #the less arguments the better
    contentSwapped = nothing

    a = findall(x -> x == aContent, _view)
    #a = a[offset]
    a = a[firstindex(arr)]

    b = findall(x -> x == bContent, _view)
    b = b[lastindex(b)] # copy(b[length(b)])   # -offset])

    if aContent > bContent
        _view[a], _view[b] = _view[b], _view[a] #swap
        contentSwapped = true
        #   _first = arr[a]
        #  _last = arr[b]
        println(_view[a], " ", _view[b], contentSwapped)

    elseif aContent < bContent
        # arr[a], arr[b] = arr[a], arr[b] # nothing
        contentSwapped = false
        println(_view[a], " ", _view[b], contentSwapped)

    elseif aContent == bContent
        #personal preference solution , the first one close to lower bound  is at first

        contentSwapped = false
        println(_view[a], " ", _view[b], contentSwapped)

    end

    return a, b, contentSwapped #returns index (more practical)
end
