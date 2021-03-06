//
//  ProductCard.swift
//  FoodProductCard
//
//  Created by Jean-Marc Boullianne on 11/17/19.
//  Copyright © 2019 Jean-Marc Boullianne. All rights reserved.
//

import SwiftUI

struct ProductCard: View {
    
    var image:Image     // Featured Image
    var price:Double    // USD
    var title:String    // Product Title
    var description:String // Product Description
    var ingredientCount:Int // # of Ingredients
    var peopleCount:Int     // Servings
    var category:String?    // Optional Category
    var buttonHandler: (()->())?
    
    init(title:String, description:String, image:Image, price:Double, peopleCount:Int, ingredientCount:Int, category:String?, buttonHandler: (()->())?) {
        
        self.title = title
        self.description = description
        self.image = image
        self.price = price
        self.peopleCount = peopleCount
        self.ingredientCount = ingredientCount
        self.category = category
        self.buttonHandler = buttonHandler
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Main Featured Image - Upper Half of Card
            self.image
                .resizable()
                .scaledToFill()
                .frame(minWidth: nil, idealWidth: nil, maxWidth: UIScreen.main.bounds.width, minHeight: nil, idealHeight: nil, maxHeight: 300, alignment: .center)
                .clipped()
                .overlay(
                    Text("LOW FAT")
                        .fontWeight(Font.Weight.medium)
                        .font(Font.system(size: 16))
                        .foregroundColor(Color.white)
                        .padding([.leading, .trailing], 16)
                        .padding([.top, .bottom], 8)
                        .background(Color.black.opacity(0.5))
                        .mask(RoundedCorners(tl: 0, tr: 0, bl: 0, br: 15))
                    , alignment: .topLeading)
            
            // Stack bottom half of card
            VStack(alignment: .leading, spacing: 6) {
                Text(self.title)
                    .fontWeight(Font.Weight.heavy)
                Text(self.description)
                    .font(Font.custom("HelveticaNeue-Bold", size: 16))
                    .foregroundColor(Color.gray)
                
                // 'Based on:' Horizontal Category Stack
                HStack(alignment: .center, spacing: 6) {
                    
                    if category != nil {
                        Text("Based on:")
                            .font(Font.system(size: 13))
                            .fontWeight(Font.Weight.heavy)
                        HStack {
                            Text(category!)
                            .font(Font.custom("HelveticaNeue-Medium", size: 12))
                                .padding([.leading, .trailing], 10)
                                .padding([.top, .bottom], 5)
                            .foregroundColor(Color.white)
                        }
                        .background(Color(red: 43/255, green: 175/255, blue: 187/255))
                        .cornerRadius(7)
                        Spacer()
                    }
                    
                    HStack(alignment: .center, spacing: 0) {
                        Text("Ingredients-")
                            .foregroundColor(Color.gray)
                        Text("\(self.ingredientCount)")
                    }.font(Font.custom("HelveticaNeue", size: 14))
                    
                }
                .padding([.top, .bottom], 8)
                
                // Horizontal Line separating details and price
                HorizontalLine(color: Color.gray.opacity(0.3))
                    .padding([.leading, .trailing], -12)
                
                // Price and Buy Now Stack
                HStack(alignment: .center, spacing: 4) {
                    Text(String.init(format: "$%.2f", arguments: [self.price]))
                        .fontWeight(Font.Weight.heavy)
                    Text("for 2 people")
                        .font(Font.system(size: 13))
                        .fontWeight(Font.Weight.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                    Image("Plus-Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15, alignment: .center)
                        .colorMultiply(Color(red: 231/255, green: 119/255, blue: 112/255))
                        .onTapGesture {
                            self.buttonHandler?()
                    }
                    Text("BUY NOW")
                        .fontWeight(Font.Weight.heavy)
                        .foregroundColor(Color(red: 231/255, green: 119/255, blue: 112/255))
                        .onTapGesture {
                            self.buttonHandler?()
                        }
                    
                }.padding([.top, .bottom], 8)
                

            }
            .padding(12)
            
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
    }
}

struct ProductCard_Previews: PreviewProvider {
    static var previews: some View {
        ProductCard(title: "SMOOTHIE BOWL", description: "With extra coconut", image: Image("Smoothie_Bowl"), price: 15.00, peopleCount: 2, ingredientCount: 12, category: "FEELING FIT", buttonHandler: nil)
    }
}
